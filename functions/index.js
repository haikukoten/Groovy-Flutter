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
            // Get user value
            var userSnapshotValue = userSnapshot.val();
            // Get key of user that will receive new budget
            var userKey = Object.keys(userSnapshot.val())[0];
            // Get user object
            var user = userSnapshotValue[userKey];

            // Get shared budget
            var budgetSnapshot = await admin.database().ref(`/users/${context.params.userId}/budgets`).orderByChild('key').equalTo(context.params.budgetId).once("value").then(budgetSnapshot => {
                return budgetSnapshot;
            });

            var budgetSnapshotValue = budgetSnapshot.val();
            // Get budget object
            var budget = budgetSnapshotValue[Object.keys(budgetSnapshotValue)[0]];
            return await admin.database().ref(`users/${userKey}/budgets`).push(budget);
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
            // Get key of user that will receive new budget
            var userKey = Object.keys(userSnapshot.val())[0];

            // Get shared budget from current user
            var budgetSnapshot = await admin.database().ref(`/users/${context.params.userId}/budgets`).orderByChild('key').equalTo(context.params.budgetId).once("value").then(budgetSnapshot => {
                return budgetSnapshot;
            });

            var budgetSnapshotValue = budgetSnapshot.val();
            // Get budget object
            var budget = budgetSnapshotValue[Object.keys(budgetSnapshotValue)[0]];

            // Get equivalent budget from selected shared user (to be removed)
            var toBeRemovedBudgetSnapshot = await admin.database().ref(`/users/${userKey}/budgets`).orderByChild('key').equalTo(budget['key']).once("value").then(toBeRemovedBudgetSnapshot => {
                return toBeRemovedBudgetSnapshot;
            });

            if (toBeRemovedBudgetSnapshot === null) {
                return false;
            } else {
                var toBeRemovedBudgetSnapshotValue = toBeRemovedBudgetSnapshot.val();
                var toBeRemovedBudgetKey = Object.keys(toBeRemovedBudgetSnapshotValue)[0];
                // Remove budget from shared user
                return await admin.database().ref(`users/${userKey}/budgets/${toBeRemovedBudgetKey}`).remove();
            }
        }
    });