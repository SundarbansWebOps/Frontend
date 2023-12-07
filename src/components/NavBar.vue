<template>
    <section class="bg-white dark:bg-black">
        <nav x-data="{ isOpen: false }" class="container px-6 py-4 mx-auto lg:flex lg:justify-between lg:items-center">
            <div class="flex items-center text-2xl font-bold dark:text-white flex justify-between"><a href="#"
                    class="flex my-auto gap-2"><img class="w-auto h-8 sm:h-10 my-auto" src="../assets/sundarbans2.png" alt="">
                    Sundarbans </a><!-- Mobile menu button -->
                <div class="flex lg:hidden"><button x-cloak="" type="button"
                    class="text-gray-500 dark:text-gray-200 hover:text-gray-600 dark:hover:text-gray-400 focus:outline-none focus:text-gray-600 dark:focus:text-gray-400"
                    aria-label="toggle menu"><svg x-show="!isOpen" xmlns="http://www.w3.org/2000/svg" class="w-6 h-6"
                        fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M4 8h16M4 16h16"></path>
                    </svg><svg x-show="isOpen" xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none"
                        viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"></path>
                    </svg></button></div>
        </div><!-- Mobile Menu open: "block", Menu closed: "hidden" -->
        <div x-cloak=""
            class="opacity-0 -translate-x-full absolute inset-x-0 z-20 w-full px-6 py-4 transition-all duration-300 ease-in-out bg-white shadow-md lg:bg-transparent lg:dark:bg-transparent lg:shadow-none dark:bg-black lg:mt-0 lg:p-0 lg:top-0 lg:relative lg:w-auto lg:opacity-100 lg:translate-x-0 lg:flex lg:items-center">
            <div class="flex flex-col space-y-4 lg:mt-0 lg:flex-row lg:-px-8 lg:space-y-0">
    <router-link
      to="/"
      class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
    >
      Home
    </router-link>
    <router-link
      to="/events"
      class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
    >
      Events
    </router-link>
    <router-link
      to="/gallery"
      class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
    >
      Gallery
    </router-link>
    <router-link
      to="/council"
      class="text-gray-700 transition-colors duration-300 transform lg:mx-8 dark:text-gray-200 dark:hover:text-blue-400 hover:text-blue-500"
    >
      Council
    </router-link>
  </div><!-- <a class="block px-5 py-2 mt-4 text-sm text-center text-white capitalize bg-blue-600 rounded-lg lg:mt-0 hover:bg-blue-500 lg:w-auto"
                    href="#">
                    Login
                </a> --><a href="#"
                class="flex items-center justify-center px-2 text-gray-600 transition-colors duration-300 transform border rounded-lg dark:border-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600">
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
                            fill="#1976D2"></path>
                    </svg></div><span class="w-5/6 px-1 py-2 font-bold text-center">Sign In</span>
            </a>
        </div>
    </nav>
</section></template>
<script>
export default{
    name : 'NavBar'
}
</script>