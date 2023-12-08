<template>
    <div id="app">
      <nav class="navbar navbar-expand-lg bg-body-tertiary bg-white dark:bg-black">
          <div class="container-fluid">
              <router-link to="/" class="navbar-brand" >
                  <img src="../assets/sundarbans2.png" alt="Logo" width="26" height="24" class="d-inline-block align-text-top "> 
              </router-link>
                  <strong >Sundarbans</strong>
              <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
                  <span class="navbar-toggler-icon "></span>
              </button>
              <div class="collapse navbar-collapse" id="navbarSupportedContent">
                  <ul class="navbar-nav me-auto mb-2 mb-lg-0">
                      <li class="nav-item">
                        <router-link
                            to="/"
                            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
                            >
                            Home
                        </router-link>
                      </li>
                      <li class="nav-item">
                        <router-link
                            to="/events"
                            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
                            >
                            Events
                        </router-link>
                      </li>
                      <li class="nav-item">
                        <router-link
                            to="/gallery"
                            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
                            >
                            Gallery
                        </router-link>
                      </li>
                      <li class="nav-item">
                        <router-link
                            to="/council"
                            class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
                            >
                            Council
                            </router-link>
                      </li>
                      <li class="nav-item">
                        <div>
                            <a href="#" class="flex items-center justify-center px-2 text-gray-600 transition-colors duration-300 transform border rounded-lg dark:border-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600">
                                <div class="px-1 py-1"><svg class="w-6 h-6" viewBox="0 0 40 40">
                                    <path
                                        d="M36.3425 16.7358H35V16.6667H20V23.3333H29.4192C28.045 27.2142 24.3525 30 20 30C14.4775 30 10 25.5225 10 20C10 14.4775 14.4775 9.99999 20 9.99999C22.5492 9.99999 24.8683 10.9617 26.6342 12.5325L31.3483 7.81833C28.3717 5.04416 24.39 3.33333 20 3.33333C10.7958 3.33333 3.33335 10.7958 3.33335 20C3.33335 29.2042 10.7958 36.6667 20 36.6667C29.2042 36.6667 36.6667 29.2042 36.6667 20C36.6667 18.8825 36.5517 17.7917 36.3425 16.7358Z"
                                        fill="#FFC107"></path>
                                    <path
                                        d="M5.25497 12.2425L10.7308 16.2583C12.2125 12.59 15.8008 9.99999 20 9.99999C22.5491 9.99999 24.8683 10.9617 26.6341 12.5325L31.3483 7.81833C28.3716 5.04416 24.39 3.33333 20 3.33333C13.5983 3.33333 8.04663 6.94749 5.25497 12.2425Z"
                                        fill="#FF3D00"></path>
                                    <path
                                        d="M20 36.6667C24.305 36.6667 28.2167 35.0192 31.1742 32.34L26.0159 27.975C24.3425 29.2425 22.2625 30 20 30C15.665 30 11.9842 27.2359 10.5975 23.3784L5.16254 27.5659C7.92087 32.9634 13.5225 36.6667 20 36.6667Z"
                                        fill="#4CAF50"></path>
                                    <path
                                        d="M36.3425 16.7358H35V16.6667H20V23.3333H29.4192C28.7592 25.1975 27.56 26.805 26.0133 27.9758C26.0142 27.975 26.015 27.975 26.0158 27.9742L31.1742 32.3392C30.8092 32.6708 36.6667 28.3333 36.6667 20C36.6667 18.8825 36.5517 17.7917 36.3425 16.7358Z"
                                        fill="#1976D2"></path></svg>
                                </div><span class="w-5/6 px-1 py-2 font-bold text-center">Sign In</span>
                            </a>
                        </div>
                      </li>
                  </ul>
              </div>
          </div>
      </nav>
    </div>
  </template>
  
  <script>
  export default {
    name : 'NavBar',

    methods:{
    }
  }
  </script>
  
  <style>
  .-fillnav-gradient{
    background: linear-gradient(to right, #16c0b0, #84cf6a);
    color: #fff;
    font-variant: small-caps;
  }
  </style>