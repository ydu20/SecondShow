var admin = require("firebase-admin");
var serviceAccount = require("./secondshow-service-account-key.json");

var email = 'jhu20@gmail.com'

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

admin.auth().getUserByEmail(email)
    .then(userRecord => {
        return admin.auth().updateUser(userRecord.uid, { emailVerified: true })
    })
    .then(() => {
        console.log('Successfully modified verification status:', email);
    })
    .catch(error => {
        console.error('Error modifying verification status:', error);
    });
