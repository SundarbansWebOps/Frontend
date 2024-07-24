<template>
    <NavBar></NavBar>
    <div class="container">
      <h1>Privacy Policy for Sundarbans</h1>
      <p>Sundarbans House is a part of IIT Madras BS Degree Student Welfare Activities. We are committed to protecting the privacy of our users. This privacy policy outlines how we collect, use, and protect your information when you visit sundarbans.iitmbs.org.</p>
  
      <h2>Information We Collect:</h2>
      <ul>
        <li>Student Email IDs: We collect student email IDs provided by IIT Madras BS Degree for authentication purposes.</li>
        <li>Group Number: We collect group numbers provided by IIT Madras BS Degree for organizational purposes.</li>
        <li>Name: We collect user names provided by IIT Madras BS Degree for identification purposes.</li>
        <li>Google Sign-In: We use Google Sign-In to authenticate users and fetch user names and photos from Google. This is solely for the purpose of verifying the identity of the user accessing the page.</li>
        <li>Location Coordinates : We capture location coordinates only for those users who want to see their neighbours.</li>
      </ul>
  
      <h2>Use of Information:</h2>
      <p>We do not share user information with any company or organization. The information collected is used solely for authentication and organizational purposes within Sundarbans House.</p>
  
      <h2>Google Sign-In:</h2>
      <ul>
        <li>We use Google Sign-In to authenticate users accessing our website.</li>
        <li>When you sign in with Google, we fetch your name and photo from Google to display on your user profile.</li>
        <li>This information is used only for the purpose of enhancing user experience and identifying users within the Sundarbans community.</li>
      </ul>
  
      <h2>Data Security:</h2>
      <p>We have implemented appropriate security measures to protect your information from unauthorized access, misuse, or alteration. Your information is stored securely and accessible only to authorized personnel. Our Backend Server & Frontend Server is hosted on a server provided by IITM BS Degree Team (POD Webops). Our Backend Code is private & all the secret credentilas are secure. Users data is safe.</p>
  
      <h2>User Rights:</h2>
      <ul>
        <li>You have the right to access, update, or delete your personal information. If you wish to exercise these rights, please contact us using the provided contact information below.</li>
        <li>You have the right to withdraw consent for the collection and use of your information at any time.</li>
      </ul>
  
      <h2>Policy Updates:</h2>
      <p>This privacy policy is subject to change. Any updates will be reflected on this page. We encourage you to review this policy periodically.</p>
  
      <h2>Contact Us:</h2>
      <p>If you have any questions, concerns, or requests regarding your privacy or this privacy policy, please contact us at <a href="mailto:sundarbans-webad@ds.study.iitm.ac.in">sundarbans-webad@ds.study.iitm.ac.in</a>.</p>
    </div>
  </template>
  
  <script>
  import NavBar from './NavBar.vue';
  export default {
    name: 'PrivacyPolicy',
    components: {
    NavBar,
  },
  }
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
  
