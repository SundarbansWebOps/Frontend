import HomePage from './components/HomePage.vue'
import ClubPage from './components/ClubPage.vue'
import VideoGallery from './components/VideoGallery.vue'
import EventsPage from './components/EventsPage.vue'
import CouncilPage from './components/CouncilPage.vue'

// Temporary no-backend versions
import HomePageNoBackend from './components/HomePageNoBackend.vue'
import ClubPageNoBackend from './components/ClubPageNoBackend.vue'
import EventsPageNoBackend from './components/EventsPageNoBackend.vue'
import CouncilPageNoBackend from './components/CouncilPageNoBackend.vue'
import UserPageNoBackend from './components/UserPageNoBackend.vue'
import UserPage from './components/UserPage.vue'
import PhotoCompetition from './components/PhotoCompetition.vue'
import EventSlug from './components/EventSlug.vue'
import PrivacyPolicy from './components/PrivacyPolicy.vue'
import NotesPage from './components/NotesPage.vue'
import WhatsAppLinks from './components/WhatsAppLinks.vue'
import StudyGroups from './components/StudyGroups.vue'
import StudyBuddy from './components/StudyBuddy.vue'
import ChatBot from './components/ChatBot.vue'
import NotFound from './components/NotFound.vue'
import GLDashboard from './components/GLDashboard.vue'
import SDSDashboard from './components/SDSDashboard.vue'
import Council2425 from './components/Council2425.vue'




import { createRouter, createWebHistory } from 'vue-router'



const routes = [
    {
        name: 'HomePage',
        component: HomePageNoBackend,  // Public home uses no-backend demo
        path: '/'
    },
    {
        name: 'HomePageTemp',
        component: HomePageNoBackend,
        path: '/temp'
    },
    {
        name: 'HomePageOriginal',
        component: HomePage,
        path: '/home-original'  // Original with backend dependency
    },
    {
        name: 'ClubPage',
        component: ClubPageNoBackend,  // Public clubs uses no-backend demo
        path: '/clubs'
    },
    {
        name: 'ClubPageTemp',
        component: ClubPageNoBackend,
        path: '/clubs-temp'
    },
    {
        name: 'ClubPageOriginal',
        component: ClubPage,
        path: '/clubs-original'  // Original with backend dependency
    },
    {
        name: 'VideoGallery',
        component: VideoGallery,
        path: '/gallery'
    },
    {
        name: 'EventsPage',
        component: EventsPageNoBackend,  // Public events uses no-backend demo
        path: '/events'
    },
    {
        name: 'EventsPageTemp',
        component: EventsPageNoBackend,
        path: '/events-temp'
    },
    {
        name: 'EventsPageOriginal',
        component: EventsPage,
        path: '/events-original'  // Original with backend dependency
    },
    {
        name: 'CouncilPage',
        component: CouncilPageNoBackend, // Public council page uses no-backend demo
        path: '/council2324'
    },
    {
        name: 'UserPage',
        component: UserPageNoBackend,  // Temporary: using no-backend version
        path: '/user'
    },
    {
        name: 'UserPageOriginal',
        component: UserPage,
        path: '/user-original'  // Original with backend dependency
    },
    {
        name: 'NotesPage',
        component: NotesPage,
        path: '/notes'
    },
    {
        name: 'WhatsAppLinks',
        component: WhatsAppLinks,
        path: '/whatsapp'
    },
    {
        name: 'StudyGroups',
        component: StudyGroups,
        path: '/study-groups'
    },
    // TEMPORARILY DISABLED - BACKEND DEPENDENT ROUTES
    /*
    {
        name: 'StudyBuddy',
        component: StudyBuddy,
        path: '/studybuddy'
    },
    */
    {
        name: 'PhotoCompetition',
        component: PhotoCompetition,
        path: '/iitmbs_friends_photo_competition'
    },
    {
        name: 'EventSlug',
        component: EventSlug,
        path: '/event/:slug'
    },
    {
        name: 'PrivacyPolicy',
        component: PrivacyPolicy,
        path: '/privacy-policy'
    },
    {
        name: 'ChatBot',
        component: ChatBot,
        path: '/chatbot'
    },
    {
        path: '/:catchAll(.*)',
        component: NotFound
    },
    {
        path: '/GLDashboard',
        component: GLDashboard
    },
    {
        path: '/SDSDashboard',
        component: SDSDashboard
    },
    {
        path: '/council',
        component: CouncilPageNoBackend  // Temporary: using no-backend version
    },
    {
        path: '/council-temp',
        component: CouncilPageNoBackend
    },
    {
        path: '/council-original',
        component: Council2425  // Original with backend dependency
    },
    // TEMPORARILY DISABLED - BACKEND DEPENDENT ROUTES
    /*
    {
        path: '/grp',
        component: () => import('./components/GRP.vue')
    },
    {
        path: '/grp/:id',
        component: () => import('./components/GRPDetails.vue')
    },
    {
        path: '/grp_admin',
        component: () => import('./components/GRPAdmin.vue')
    }
    */
];

const router = createRouter({
    history: createWebHistory(),
    routes
})

export default router