<template>
  <div>
    <NavBar></NavBar>
    <div class="container">
      <h1>Privacy Policy for Sundarbans House</h1>
      <p>
        Welcome to sundarbans.iitmbs.org, the student activities website for Sundarbans
        House, IIT Madras BS Degree. This Privacy Policy outlines how personal
        information is collected, used, and protected.
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
              number to access the group links, and it is stored for group joining request approval.
            </li>
            <li>
              <strong>Location Coordinates (optional):</strong> Collected with permission for the StudyBuddy feature to calculate and display distances
              to nearby users. A mathematical formula is used to calculate approximate distances.
              Exact location coordinates are not shared with anyone.
            </li>
            <li>
              <strong>Social Media URLs (optional):</strong> Information that can be updated
              to share with others in the StudyBuddy feature.
            </li>
          </ul>
        </section>

        <section id="use-of-information">
          <h2>Use of Information</h2>
          <ul>
            <li>Users are authenticated, and access is granted to the profile page and relevant features.</li>
            <li>The allotted group and WhatsApp group link are displayed on the profile.</li>
            <li>
              The approximate distance to nearby users is calculated and displayed in the StudyBuddy
              feature (only approximate distance is shared).
            </li>
            <li>WhatsApp numbers are verified for joining the allotted group.</li>
            <li>Social media URLs (if provided) are displayed to other users in the StudyBuddy feature.</li>
          </ul>
        </section>

        <section id="data-storage-and-security">
          <h2>Data Storage and Security</h2>
          <p>
            Appropriate security measures are implemented to protect information
            from unauthorized access, misuse, or alteration. Information is
            stored securely and is accessible only to authorized personnel. No
            third-party services are used for storing data.
          </p>
        </section>

        <section id="data-sharing">
          <h2>Data Sharing</h2>
          <p>
            Personal information is not sold, traded, or otherwise transferred to
            outside parties. Location coordinates are not shared with anyone.
            Only the approximate relative distance to the nearest 20 users is visible
            to them.
          </p>
        </section>

        <section id="user-rights">
          <h2>User Rights</h2>
          <ul>
            <li>Users have the right to access, update, or delete their personal information at any time.</li>
            <li>Consent for the collection and use of information can be withdrawn at any time.</li>
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
            Google Sign-In. It displays the allotted group and the WhatsApp group link.
            Email address, name, and profile image are fetched from Google. The WhatsApp number can be
            updated for group verification purposes.
          </p>
        </section>

        <section id="studybuddy-feature">
          <h3>StudyBuddy Feature</h3>
          <p>
            <b>Disclaimer: This is a student-run platform and it is not endorsed by the IITM BS degree program in any way. Students can join the platform at their personal discretion.</b>
          </p>
          <p>
            The StudyBuddy feature helps find nearby students. It collects the email,
            name, and profile image through Google Sign-In, and location coordinates
            with permission. These coordinates are used to calculate and display the
            nearest 20 students. Other users can see the name, profile image, and
            approximate distance from them. Social media profiles can be updated and
            others' social media links can be viewed. Data can be deleted at any time.
          </p>
          <p>Note: Calculated approximate distances may be inaccurate.</p>
        </section>

        <section id="policy-updates">
          <h2>Policy Updates</h2>
          <p>
            This Privacy Policy is subject to change. Any updates will be reflected on
            this page. It is encouraged to review this policy periodically.
          </p>
        </section>

        <section id="contact-us">
          <h2>Contact Us</h2>
          <p>
            For any questions or concerns about this Privacy Policy or privacy,
            please contact us at:
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
