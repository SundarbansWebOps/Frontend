import HomePage from './components/HomePage.vue'
import ClubPage from './components/ClubPage.vue'
import VideoGallery from './components/VideoGallery.vue'
import EventsPage from './components/EventsPage.vue'
import CouncilPage from './components/CouncilPage.vue'
import UserPage from './components/UserPage.vue'
import PhotoCompetition from './components/PhotoCompetition.vue'
import EventSlug from './components/EventSlug.vue'
import PrivacyPolicy from './components/PrivacyPolicy.vue'
import NotesPage from './components/NotesPage.vue'
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
        component: HomePage,
        path: '/'
    },
    {
        name: 'ClubPage',
        component: ClubPage,
        path: '/clubs'
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
        path: '/council2324'
    },
    {
        name: 'UserPage',
        component: UserPage,
        path: '/user'
    },
    {
        name: 'NotesPage',
        component: NotesPage,
        path: '/notes'
    },
    {
        name: 'StudyGroups',
        component: StudyGroups,
        path: '/study-groups'
    },
    {
        name: 'StudyBuddy',
        component: StudyBuddy,
        path: '/studybuddy'
    },
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
        component: Council2425
    }, {
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
];

const router = createRouter({
    history: createWebHistory(),
    routes
})

export default router