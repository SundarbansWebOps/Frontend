<template>
  <div>
    <NavBar></NavBar>
    <div class="container">
      <h1>Privacy Policy for Sundarbans House</h1>
      <p>
        Welcome to sundarbans.iitmbs.org, the student activities website for Sundarbans
        House, IIT Madras BS Degree. This Privacy Policy outlines how we collect,
        use, and protect your personal information.
      </p>

      <div class="button-container">
        <button @click="printDocument" class="action-button">Print</button>
        <a href="https://drive.google.com/u/0/uc?id=1vNx3MT7kfmVec7WAtKiuSjlTrazUc7-f&export=download"><button class="action-button">Download PDF</button></a>
      </div>

      <div ref="policyContent" class="policy-content">
        <section id="information-collected">
          <h2>Information We Collect</h2>
          <ul>
            <li>
              <strong>Email Address (with consent):</strong> Collected during Google Sign-In
              for authentication purposes.
            </li>
            <li>
              <strong>Name and Profile Image:</strong> Fetched from Google during Sign-In
              for identity verification and display purposes.
            </li>
            <li>
              <strong>WhatsApp Number (optional):</strong> Collected only from Sundarbans House members
              to verify their request to join the WhatsApp group of their allotted group. Members update their
              number to access the group links, and we store it for group joining request approval.
            </li>
            <li>
              <strong>Location Coordinates (optional):</strong> Collected with your
              permission for the StudyBuddy feature to calculate and display distances
              to nearby users. We use a mathematical formula to calculate approximate distances.
              Your exact location coordinates are not shared with anyone.
            </li>
            <li>
              <strong>Social Media URLs (optional):</strong> Information you can update
              to share with others in the StudyBuddy feature.
            </li>
          </ul>
        </section>

        <section id="use-of-information">
          <h2>Use of Information</h2>
          <ul>
            <li>Authenticate users and grant access to the profile page and relevant features.</li>
            <li>Display your allotted group and WhatsApp group link on your profile.</li>
            <li>
              Calculate and display the approximate distance to nearby users in the StudyBuddy
              feature (only approximate distance is shared).
            </li>
            <li>Verify your WhatsApp number for joining the allotted group.</li>
            <li>Display your social media URLs (if provided) to other users in the StudyBuddy feature.</li>
          </ul>
        </section>

        <section id="data-storage-and-security">
          <h2>Data Storage and Security</h2>
          <p>
            We implement appropriate security measures to protect your information
            from unauthorized access, misuse, or alteration. Your information is
            stored securely and is accessible only to authorized personnel. We do not
            use any third-party services for storing your data.
          </p>
        </section>

        <section id="data-sharing">
          <h2>Data Sharing</h2>
          <p>
            We do not sell, trade, or otherwise transfer your personal information to
            outside parties. Your location coordinates are not shared with anyone.
            Only the approximate relative distance to the nearest 20 users is visible
            to them.
          </p>
        </section>

        <section id="user-rights">
          <h2>User Rights</h2>
          <ul>
            <li>You have the right to access, update, or delete your personal information at any time.</li>
            <li>You can withdraw your consent for the collection and use of your information at any time.</li>
          </ul>
        </section>

        <section id="information-about-our-website">
          <h2>Information About Our Website</h2>
          <h3>Static Pages</h3>
          <p>Our website contains the following static pages that display content:</p>
          <ul>
            <li><strong>Home Page:</strong> Introduction to the house, events, and videos.</li>
            <li><strong>Events Page:</strong> Information on previous student activities and upcoming sessions.</li>
            <li><strong>Gallery Page:</strong> YouTube videos showcasing our activities.</li>
            <li><strong>Council Page:</strong> Details about the council members.</li>
            <li><strong>Notes Page:</strong> Notes and resources for students.</li>
          </ul>

          <h3>Profile Page</h3>
          <p>
            The profile page is accessible only to Sundarbans House members after
            Google Sign-In. It displays your allotted group and the WhatsApp group link.
            Your email address, name, and profile image are fetched from Google. You can
            update your WhatsApp number for group verification purposes.
          </p>
        </section>

        <section id="studybuddy-feature">
          <h3>StudyBuddy Feature</h3>
          <p>
            The StudyBuddy feature helps you find nearby students. It collects your email,
            name, and profile image through Google Sign-In, and your location coordinates
            with your permission. We use these coordinates to calculate and display the
            nearest 20 students. Other users can see your name, profile image, and
            approximate distance from them. You can update your social media profile and
            view others' social media links. You can delete your data at any time.
          </p>
        </section>

        <section id="policy-updates">
          <h2>Policy Updates</h2>
          <p>
            This Privacy Policy is subject to change. Any updates will be reflected on
            this page. We encourage you to review this policy periodically.
          </p>
        </section>

        <section id="contact-us">
          <h2>Contact Us</h2>
          <p>
            If you have any questions or concerns about this Privacy Policy or your
            privacy, please contact us at:
            <a href="mailto:sundarbans-webad@ds.study.iitm.ac.in">sundarbans-webad@ds.study.iitm.ac.in</a>.
          </p>
        </section>
      </div>
    </div>
  </div>
</template>

<script>
import NavBar from './NavBar.vue';

export default {
  name: 'PrivacyPolicy',
  components: {
    NavBar,
  },
  methods: {
    printDocument() {
      window.print();
    },
  },
};
</script>

<style scoped>
.container {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
  font-family: 'Arial', sans-serif;
}

h1, h2, h3 {
  text-align: center;
  margin-top: 20px;
  font-weight: bold;
}

p, ul {
  margin-bottom: 20px;
  line-height: 1.5;
}

ul {
  list-style-type: disc;
  padding-left: 20px;
}

li {
  margin-bottom: 10px;
}

.button-container {
  text-align: center;
  margin-bottom: 20px;
}

.action-button {
  background-color: #910404; /* Button color */
  color: white; /* Text color */
  border: none;
  padding: 10px 20px;
  margin: 5px;
  border-radius: 5px;
  cursor: pointer;
  font-size: 16px;
}

.action-button:hover {
  background-color: #7a0303; /* Darker shade on hover */
}

.policy-content {
  background-color: #f9f9f9;
  border: 1px solid #ddd;
  border-radius: 5px;
  padding: 20px;
  margin-bottom: 20px;
}

@media (max-width: 600px) {
  .container {
    padding: 10px;
  }
}
</style>
