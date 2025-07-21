const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.createCompanyUser = functions.https.onCall(async (data, context) => {
  // Only allow signed-in users (admins) to call this function
  if (!context.auth) {
        throw new functions.https.HttpsError(
                "unauthenticated",
                "Not signed in",
        );
  }

  // Optionally: Check if context.auth.uid is an admin in the company
  const {email, password, companyId, userData} = data;

  // 1. Create Auth user
  let userRecord;
  try {
        userRecord = await admin.auth().createUser({
                email,
                password,
        });
  } catch (e) {
        throw new functions.https.HttpsError(
                "already-exists",
                "Email already in use",
        );
  }

  // 2. Write to /companies/{companyId}/users/{newUid}
  await admin.firestore().collection("companies")
      .doc(companyId)
      .collection("users")
      .doc(userRecord.uid)
      .set(userData);

  // 3. Write to /userCompany/{newUid}
  await admin.firestore().collection("userCompany")
      .doc(userRecord.uid)
      .set({email, companyId});

  return {
      success: true,
      uid: userRecord.uid,
  };
});