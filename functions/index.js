// The Cloud Functions for Firebase SDK to create Cloud Functions and setup triggers.
const functions = require('firebase-functions');

// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');
admin.initializeApp();

// Listens for new user emails added to /users/{userId}/budgets/{budgetId}/sharedWith and adds budget to that user
exports.shareBudget = functions.database.ref('/users/{userId}/budgets/{budgetId}/sharedWith/')
    .onUpdate(async (change, context) => {

        var sharedWithListBefore = change.before.val();
        var sharedWithListAfter = change.after.val();

        // Email address was deleted so let onDelete function handle it
        if (sharedWithListBefore.length > sharedWithListAfter.length) {
            return null;
        }

        // Get user from shared email
        var sharedEmail = sharedWithListAfter[sharedWithListAfter.length - 1];

        var userSnapshot = await admin.database().ref('/users').orderByChild('email').equalTo(sharedEmail).once("value").then(userSnapshot => {
            return userSnapshot;
        });

        if (userSnapshot.val() === null) {
            return false;
        } else {
            // Get receiving user value
            var userSnapshotValue = userSnapshot.val();
            // Get key of receiving user
            var userKey = Object.keys(userSnapshot.val())[0];
            // Get receivng user object
            var user = userSnapshotValue[userKey];
            // Get receiving user device tokens
            var deviceTokens = user.deviceTokens;

            // Get shared budget
            var budgetSnapshot = await admin.database().ref(`/users/${context.params.userId}/budgets`).orderByChild('key').equalTo(context.params.budgetId).once("value").then(budgetSnapshot => {
                return budgetSnapshot;
            });

            var budgetSnapshotValue = budgetSnapshot.val();
            // Get budget object
            var budget = budgetSnapshotValue[Object.keys(budgetSnapshotValue)[0]];

            // Get current user so shared user will get current user's name in notification
            var currentUserSnapshot = await admin.database().ref(`/users/${context.params.userId}`).once("value").then(currentUserSnapshot => {
                return currentUserSnapshot;
            });

            // Get current user object
            var currentUser = currentUserSnapshot.val();
            var currentUserName = currentUser.name;

            // Notification details.
            const payload = {
                notification: {
                    body: `${currentUserName} shared a budget with you 💸`,
                    title: "",
                },
                data: {
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                },
            };

            return await admin.database().ref(`users/${userKey}/budgets`).push(budget).then(_ => {
                if (deviceTokens !== null) {
                    // Send notification to all devices of receiving user
                    return admin.messaging().sendToDevice(deviceTokens, payload);
                } else {
                    return null;
                }
            });
        }
    });


// Listens for user emails deleted from /users/{userId}/budgets/{budgetId}/sharedWith/{sharedWIthId} 
// and removes the budget from that user email that was removed
exports.removeShareBudget = functions.database.ref('/users/{userId}/budgets/{budgetId}/sharedWith/{sharedWithId}')
    .onDelete(async (snapshot, context) => {
        // Get user from removed email
        var removedEmail = snapshot.val();
        var userSnapshot = await admin.database().ref('/users').orderByChild('email').equalTo(removedEmail).once("value").then(userSnapshot => {
            return userSnapshot;
        });

        if (userSnapshot === null) {
            return false;
        } else {
            // Get key of receiving user
            var userKey = Object.keys(userSnapshot.val())[0];

            // Get shared budget from current user
            var budgetSnapshot = await admin.database().ref(`/users/${context.params.userId}/budgets`).orderByChild('key').equalTo(context.params.budgetId).once("value").then(budgetSnapshot => {
                return budgetSnapshot;
            });

            var budgetSnapshotValue = budgetSnapshot.val();
            // Get budget object
            var budget = budgetSnapshotValue[Object.keys(budgetSnapshotValue)[0]];

            // Get equivalent budget (to be removed) from selected shared user
            var toBeRemovedBudgetSnapshot = await admin.database().ref(`/users/${userKey}/budgets`).orderByChild('key').equalTo(budget['key']).once("value").then(toBeRemovedBudgetSnapshot => {
                return toBeRemovedBudgetSnapshot;
            });

            if (toBeRemovedBudgetSnapshot === null) {
                return false;
            } else {
                var toBeRemovedBudgetSnapshotValue = toBeRemovedBudgetSnapshot.val();
                var toBeRemovedBudgetKey = Object.keys(toBeRemovedBudgetSnapshotValue)[0];

                // Remove budget promises
                var removeBudgetPromises = [];

                // Remove budget from shared user
                var removeBudget = admin.database().ref(`users/${userKey}/budgets/${toBeRemovedBudgetKey}`).remove();
                removeBudgetPromises.push(removeBudget);

                // Update all other shared budgets with new budget info
                // Get all emails
                var emails = budget.sharedWith;
                // Get user for email
                for (var email in emails) {
                    var sharedUserSnapshot = admin.database().ref('/users').orderByChild('email').equalTo(email).once("value").then(sharedUserSnapshot => {
                        return sharedUserSnapshot;
                    });
                    // Get budget for user
                    var sharedBudgetSnapshot = admin.database().ref(`/users/${sharedUserSnapshot.key}/budgets`).orderByChild('key').equalTo(budget['key']).once("value").then(sharedBudgetSnapshot => {
                        return sharedBudgetSnapshot;
                    });

                    // Update that budget with new 'isShared' and 'sharedWith' values
                    var updateBudget = admin.database().ref(`users/${sharedUserSnapshot.key}/budgets/${sharedBudgetSnapshot.key}`).set(budget);
                    removeBudgetPromises.push(updateBudget);
                }

                return Promise.all(removeBudgetPromises);
            }
        }
    });