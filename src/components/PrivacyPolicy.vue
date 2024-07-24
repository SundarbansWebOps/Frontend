<template>
  <NavBar></NavBar>
  <div class="container">
    <h1>Privacy Policy for Sundarbans</h1>
    <p>Welcome to Sundarbans House, a division of the IIT Madras BS Degree Student Welfare Activities. We are dedicated to safeguarding the privacy of our users. This Privacy Policy outlines how we collect, use, and protect your information when you visit sundarbans.iitmbs.org.</p>

    <h2>Information We Collect</h2>
    <ul>
      <li><strong>Student Email IDs:</strong> Collected for authentication purposes, provided by IIT Madras BS Degree.</li>
      <li><strong>Group Number:</strong> Collected for organizational purposes, provided by IIT Madras BS Degree.</li>
      <li><strong>Name:</strong> Collected for identification purposes, provided by IIT Madras BS Degree.</li>
      <li><strong>Google Sign-In:</strong> Used to authenticate users and fetch user names and photos from Google for identity verification.</li>
      <li><strong>Location Coordinates:</strong> Captured for users who want to see their neighbors.</li>
    </ul>

    <h2>Use of Information</h2>
    <p>We do not share user information with any external company or organization. The collected information is used solely for authentication and organizational purposes within Sundarbans House.</p>

    <h2>Google Sign-In</h2>
    <ul>
      <li>Used to authenticate users accessing our website.</li>
      <li>Fetches your name and photo from Google to display on your user profile.</li>
      <li>Information is used to enhance user experience and identify users within the Sundarbans community.</li>
    </ul>

    <h2>Data Security</h2>
    <p>We implement appropriate security measures to protect your information from unauthorized access, misuse, or alteration. Your information is stored securely and is accessible only to authorized personnel. Our Backend Server and Frontend Server are hosted on a server provided by the IITM BS Degree Team (POD Webops). Our Backend Code is private, and all secret credentials are secure, ensuring user data safety.</p>

    <h2>User Rights</h2>
    <ul>
      <li>You have the right to access, update, or delete your personal information. To exercise these rights, please contact us using the provided contact information below.</li>
      <li>You have the right to withdraw consent for the collection and use of your information at any time.</li>
    </ul>

    <h2>Policy Updates</h2>
    <p>This Privacy Policy is subject to change. Any updates will be reflected on this page. We encourage you to review this policy periodically.</p>

    <h2>Contact Us</h2>
    <p>If you have any questions, concerns, or requests regarding your privacy or this Privacy Policy, please contact us at <a href="mailto:sundarbans-webad@ds.study.iitm.ac.in">sundarbans-webad@ds.study.iitm.ac.in</a>.</p>
  </div>
</template>

<script>
import NavBar from './NavBar.vue';

export default {
  name: 'PrivacyPolicy',
  components: {
    NavBar,
  },
};
</script>

<style scoped>
.container {
  max-width: 800px;
  margin: 0 auto;
}

h1 {
  text-align: center;
}

h2 {
  margin-top: 30px;
}

p {
  margin-bottom: 20px;
}

ul {
  margin-bottom: 20px;
}

li {
  margin-bottom: 10px;
}
</style>
