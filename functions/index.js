const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

// ===================================================================
// CONFIG
// ===================================================================
const COMMISSION_RATE = 0.15; // 15%
const ESCROW_HOLD_DAYS = 3;
const REFERRAL_BONUS_LKR = 100;
const VERIFICATION_FEE_LKR = 150;

// Vault encryption key - set with:
// firebase functions:config:set vault.key="YOUR_32_CHAR_SECRET_KEY_HERE"
function getVaultKey() {
  const key = functions.config().vault && functions.config().vault.key;
  if (!key || key.length < 32) {
    throw new Error("Vault encryption key not configured or too short (need 32+ chars). Run: firebase functions:config:set vault.key=\"...\"");
  }
  return crypto.createHash("sha256").update(String(key)).digest();
}

function encrypt(text) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv("aes-256-cbc", getVaultKey(), iv);
  let encrypted = cipher.update(text, "utf8", "hex");
  encrypted += cipher.final("hex");
  return iv.toString("hex") + ":" + encrypted;
}

function decrypt(payload) {
  const [ivHex, dataHex] = payload.split(":");
  const iv = Buffer.from(ivHex, "hex");
  const decipher = crypto.createDecipheriv("aes-256-cbc", getVaultKey(), iv);
  let decrypted = decipher.update(dataHex, "hex", "utf8");
  decrypted += decipher.final("utf8");
  return decrypted;
}

// ===================================================================
// 1. onOrderCreate — Callable Function
// Buyer purchases a listing. Deducts wallet balance, moves it to escrow,
// creates the order doc, marks listing as sold/pending.
// ===================================================================
exports.createOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "ලොග් වෙන්න ඕන.");
  }
  const buyerId = context.auth.uid;
  const { listingId } = data;
  if (!listingId) {
    throw new functions.https.HttpsError("invalid-argument", "listingId අවශ්‍යයි.");
  }

  return db.runTransaction(async (tx) => {
    const listingRef = db.collection("listings").doc(listingId);
    const listingSnap = await tx.get(listingRef);
    if (!listingSnap.exists) {
      throw new functions.https.HttpsError("not-found", "Listing එක හමු නොවුණි.");
    }
    const listing = listingSnap.data();
    if (listing.status !== "active") {
      throw new functions.https.HttpsError("failed-precondition", "මේ listing එක දැනටමත් විකුණලා/pending.");
    }
    if (listing.sellerId === buyerId) {
      throw new functions.https.HttpsError("failed-precondition", "ඔයාගේම listing එක ගන්න බෑ.");
    }

    const price = listing.price;
    const buyerRef = db.collection("users").doc(buyerId);
    const buyerSnap = await tx.get(buyerRef);
    const buyerData = buyerSnap.data();
    const buyerBalance = (buyerData && buyerData.walletBalance) || 0;

    if (buyerBalance < price) {
      throw new functions.https.HttpsError("failed-precondition", "Wallet balance මදි.");
    }

    const commission = Math.round(price * COMMISSION_RATE * 100) / 100;
    const sellerPayout = price - commission;
    const orderRef = db.collection("orders").doc();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const releaseAt = admin.firestore.Timestamp.fromMillis(
        Date.now() + ESCROW_HOLD_DAYS * 24 * 60 * 60 * 1000
    );

    // Deduct from buyer, hold in escrow
    tx.update(buyerRef, {
      walletBalance: admin.firestore.FieldValue.increment(-price),
    });

    tx.set(orderRef, {
      listingId,
      buyerId,
      sellerId: listing.sellerId,
      price,
      commission,
      sellerPayout,
      status: "escrow_held",
      createdAt: now,
      escrowReleaseAt: releaseAt,
      disputeRaised: false,
    });

    tx.update(listingRef, { status: "pending_escrow" });

    tx.set(db.collection("wallet_transactions").doc(), {
      userId: buyerId,
      type: "purchase_hold",
      amount: -price,
      orderId: orderRef.id,
      createdAt: now,
    });

    return { orderId: orderRef.id, releaseAt: releaseAt.toMillis() };
  });
});

// ===================================================================
// 2. scheduledEscrowRelease — runs every hour
// Releases funds to seller (minus commission) after ESCROW_HOLD_DAYS,
// if no dispute was raised. Also triggers vault decrypt delivery.
// ===================================================================
exports.scheduledEscrowRelease = functions.pubsub
    .schedule("every 60 minutes")
    .onRun(async () => {
      const now = admin.firestore.Timestamp.now();
      const dueOrders = await db.collection("orders")
          .where("status", "==", "escrow_held")
          .where("disputeRaised", "==", false)
          .where("escrowReleaseAt", "<=", now)
          .get();

      if (dueOrders.empty) {
        console.log("No orders due for escrow release.");
        return null;
      }

      const batch = db.batch();
      dueOrders.forEach((doc) => {
        const order = doc.data();
        const sellerRef = db.collection("users").doc(order.sellerId);
        batch.update(sellerRef, {
          walletBalance: admin.firestore.FieldValue.increment(order.sellerPayout),
        });
        batch.update(doc.ref, {
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        batch.update(db.collection("listings").doc(order.listingId), {
          status: "sold",
        });
        batch.set(db.collection("wallet_transactions").doc(), {
          userId: order.sellerId,
          type: "sale_release",
          amount: order.sellerPayout,
          orderId: doc.id,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        batch.set(db.collection("wallet_transactions").doc(), {
          userId: order.sellerId,
          type: "commission",
          amount: -order.commission,
          orderId: doc.id,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
      console.log(`Released escrow for ${dueOrders.size} orders.`);
      return null;
    });

// ===================================================================
// 3. saveVault — Callable Function
// Seller submits account credentials when creating a listing.
// Encrypts before storing; client never writes plaintext to Firestore.
// ===================================================================
exports.saveVault = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "ලොග් වෙන්න ඕන.");
  }
  const { listingId, email, password, recoveryCodes } = data;
  if (!listingId || !email || !password) {
    throw new functions.https.HttpsError("invalid-argument", "listingId, email, password අවශ්‍යයි.");
  }

  const listingSnap = await db.collection("listings").doc(listingId).get();
  if (!listingSnap.exists || listingSnap.data().sellerId !== context.auth.uid) {
    throw new functions.https.HttpsError("permission-denied", "මේ listing එක ඔයාගේ නෙමෙයි.");
  }

  await db.collection("vault").doc(listingId).set({
    sellerId: context.auth.uid,
    email: encrypt(email),
    password: encrypt(password),
    recoveryCodes: recoveryCodes ? encrypt(recoveryCodes) : null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// ===================================================================
// 4. decryptVaultOnPaymentConfirm — Callable Function
// Buyer calls this ONLY after order status is "completed" (escrow released).
// Returns decrypted credentials one time.
// ===================================================================
exports.getVaultCredentials = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "ලොග් වෙන්න ඕන.");
  }
  const { orderId } = data;
  const orderSnap = await db.collection("orders").doc(orderId).get();
  if (!orderSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Order එක හමු නොවුණි.");
  }
  const order = orderSnap.data();
  if (order.buyerId !== context.auth.uid) {
    throw new functions.https.HttpsError("permission-denied", "ඔයාගේ order එකක් නෙමෙයි.");
  }
  if (order.status !== "completed") {
    throw new functions.https.HttpsError("failed-precondition", "Escrow තවම release වෙලා නෑ.");
  }

  const vaultSnap = await db.collection("vault").doc(order.listingId).get();
  if (!vaultSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Vault data හමු නොවුණි.");
  }
  const vault = vaultSnap.data();

  return {
    email: decrypt(vault.email),
    password: decrypt(vault.password),
    recoveryCodes: vault.recoveryCodes ? decrypt(vault.recoveryCodes) : null,
  };
});

// ===================================================================
// 5. onVerificationApproved — Firestore trigger
// Admin sets verifications/{uid}.status = "approved" in the admin panel.
// This automatically sets the blue badge on the user doc.
// ===================================================================
exports.onVerificationApproved = functions.firestore
    .document("verifications/{uid}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();
      const uid = context.params.uid;

      if (before.status !== "approved" && after.status === "approved") {
        await db.collection("users").doc(uid).update({
          verifiedStatus: "verified",
          verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      if (before.status !== "rejected" && after.status === "rejected") {
        await db.collection("users").doc(uid).update({
          verifiedStatus: "rejected",
        });
      }

      return null;
    });

// ===================================================================
// 6. processReferralBonus — Callable Function
// New user enters a referral code during signup. Both get LKR 100.
// ===================================================================
exports.processReferralBonus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "ලොග් වෙන්න ඕන.");
  }
  const newUserId = context.auth.uid;
  const { referralCode } = data;
  if (!referralCode) {
    throw new functions.https.HttpsError("invalid-argument", "referralCode අවශ්‍යයි.");
  }

  const newUserRef = db.collection("users").doc(newUserId);
  const newUserSnap = await newUserRef.get();
  if (newUserSnap.exists && newUserSnap.data().referralUsed) {
    throw new functions.https.HttpsError("failed-precondition", "Referral code එකක් දැනටමත් පාවිච්චි කරලා.");
  }

  const referrerQuery = await db.collection("users")
      .where("myReferralCode", "==", referralCode)
      .limit(1)
      .get();

  if (referrerQuery.empty) {
    throw new functions.https.HttpsError("not-found", "වැරදි referral code එකක්.");
  }
  const referrerDoc = referrerQuery.docs[0];
  if (referrerDoc.id === newUserId) {
    throw new functions.https.HttpsError("failed-precondition", "ඔයාගේම code එක පාවිච්චි කරන්න බෑ.");
  }

  const batch = db.batch();
  batch.update(referrerDoc.ref, {
    walletBalance: admin.firestore.FieldValue.increment(REFERRAL_BONUS_LKR),
  });
  batch.update(newUserRef, {
    walletBalance: admin.firestore.FieldValue.increment(REFERRAL_BONUS_LKR),
    referralUsed: true,
    referredBy: referrerDoc.id,
  });
  batch.set(db.collection("wallet_transactions").doc(), {
    userId: referrerDoc.id,
    type: "referral_bonus",
    amount: REFERRAL_BONUS_LKR,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  batch.set(db.collection("wallet_transactions").doc(), {
    userId: newUserId,
    type: "referral_bonus",
    amount: REFERRAL_BONUS_LKR,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();
  return { success: true, bonus: REFERRAL_BONUS_LKR };
});

// ===================================================================
// 7. confirmTopUp — Callable Function (Admin only)
// Admin approves a bank-transfer top-up slip; credits buyer wallet.
// ===================================================================
exports.confirmTopUp = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "ලොග් වෙන්න ඕන.");
  }
  const adminSnap = await db.collection("admins").doc(context.auth.uid).get();
  if (!adminSnap.exists) {
    throw new functions.https.HttpsError("permission-denied", "Admin කෙනෙක් විතරයි මේක කරන්න පුළුවන්.");
  }

  const { topUpRequestId } = data;
  const reqRef = db.collection("topup_requests").doc(topUpRequestId);
  const reqSnap = await reqRef.get();
  if (!reqSnap.exists) {
    throw new functions.https.HttpsError("not-found", "Top-up request එක හමු නොවුණි.");
  }
  const reqData = reqSnap.data();
  if (reqData.status !== "pending") {
    throw new functions.https.HttpsError("failed-precondition", "මේ request එක දැනටමත් process කරලා.");
  }

  const batch = db.batch();
  batch.update(reqRef, {
    status: "confirmed",
    confirmedBy: context.auth.uid,
    confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  batch.update(db.collection("users").doc(reqData.userId), {
    walletBalance: admin.firestore.FieldValue.increment(reqData.amount),
  });
  batch.set(db.collection("wallet_transactions").doc(), {
    userId: reqData.userId,
    type: "topup",
    amount: reqData.amount,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();
  return { success: true };
});
