import HomePage from './components/HomePage.vue'
import AboutPage from './components/AboutPage.vue'
import VideoGallery from './components/VideoGallery.vue'
import EventsPage from './components/EventsPage.vue'
import CouncilPage from './components/CouncilPage.vue'
import UserPage from './components/UserPage.vue'
import PhotoCompetition from './components/PhotoCompetition.vue'







import { createRouter, createWebHistory } from 'vue-router'



const routes = [
    {
        name: 'HomePage',
        component: HomePage,
        path: '/'
    },
    {
        name: 'AboutPage',
        component: AboutPage,
        path: '/about'
    },
    {
        name: 'VideoGallery',
        component: VideoGallery,
        path: '/gallery'
    },
    {
        name: 'EventsPage',
        component: EventsPage,
        path: '/events'
    },
    {
        name: 'CouncilPage',
        component: CouncilPage,
        path: '/council'
    },
    {
        name: 'UserPage',
        component: UserPage,
        path: '/user'
    },
    {
        name: 'PhotoCompetition',
        component: PhotoCompetition,
        path: '/iitmbs_friends_photo_competition'
    },
];

const router = createRouter({
    history: createWebHistory(),
    routes
})

export default router