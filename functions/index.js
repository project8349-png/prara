const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

// Send FCM when a new private message is created
exports.onPrivateMessage = functions.firestore.document('Messages/{chatId}/Threads/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const toUid = message.to;
    if (!toUid) return null;
    const userDoc = await db.collection('Users').doc(toUid).get();
    const token = userDoc.get('fcmToken');
    if (!token) return null;
    const payload = {
      notification: {
        title: `New message from ${message.fromName}`,
        body: message.text || 'New message',
      }
    };
    return admin.messaging().sendToDevice(token, payload);
  });

// Send FCM when a new group message created
exports.onGroupMessage = functions.firestore.document('GroupMessages/{msgId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const payload = {
      notification: {
        title: 'Study Community',
        body: message.text || 'New group message',
      }
    };
    // Broadcast: get tokens from Users collection
    const users = await db.collection('Users').where('fcmToken', '!=', null).get();
    const tokens = [];
    users.forEach(u => { if (u.get('fcmToken')) tokens.push(u.get('fcmToken')); });
    if (tokens.length === 0) return null;
    return admin.messaging().sendToDevice(tokens, payload);
  });

// Callable function to generate simple AI feedback (heuristic) for a user
exports.generateWeeklyFeedback = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  const uid = context.auth.uid;
  // Fetch last 7 days of DailyActivity
  const now = admin.firestore.Timestamp.now();
  const weekAgo = admin.firestore.Timestamp.fromMillis(now.toMillis() - 7 * 24 * 60 * 60 * 1000);
  const snaps = await db.collection('DailyActivity').where('userId', '==', uid).where('date', '>=', weekAgo).get();
  let totalStudy = 0;
  let totalSleep = 0;
  snaps.forEach(s => {
    const d = s.data();
    totalStudy += (d.studyHours || 0);
    totalSleep += (d.sleepHours || 0);
  });
  const days = snaps.size || 1;
  const avgStudy = totalStudy / days;
  const avgSleep = totalSleep / days;

  let feedback = '';
  if (avgStudy >= 4) feedback += 'Great job — you studied consistently this week! ';
  else feedback += 'Try to increase focused study sessions; aim for 2–4 hours daily. ';

  if (avgSleep >= 7) feedback += 'Your sleep is healthy. Keep it up.';
  else feedback += 'Consider improving sleep hygiene to reach 7+ hours.';

  // Save feedback to Reports collection
  await db.collection('Reports').add({ userId: uid, generatedAt: admin.firestore.FieldValue.serverTimestamp(), feedback, avgStudy, avgSleep });
  return { feedback, avgStudy, avgSleep };
});
