import { createRouter, createWebHashHistory } from 'vue-router'

// Main views
import Home          from '../views/HomeView.vue'
import About         from '../views/AboutView.vue'
import Events        from '../views/EventsView.vue'
import Study         from '../views/StudyView.vue'
import Teams         from '../views/TeamsView.vue'
import Community     from '../views/CommunityView.vue'
import Contact       from '../views/ContactView.vue'
import Login         from '../views/LoginView.vue'
import MembersLounge from '../views/MembersLoungeView.vue'
import DashboardView from '../views/DashboardView.vue'
import TechnicalView from '../views/TechnicalView.vue'
import CulturalView  from '../views/CulturalView.vue'
import ESportsView   from '../views/ESportsView.vue'

// Meetups — main + regions
import Meetups           from '../views/MeetupsView.vue'
import DelhiNCRMeetups   from '../views/meetups/DelhiMeetups.vue'
import MumbaiMeetups     from '../views/meetups/MumbaiMeetups.vue'
import BangaloreMeetups  from '../views/meetups/BangaloreMeetups.vue'
import KolkataMeetups    from '../views/meetups/KolkataMeetups.vue'
import HyderabadMeetups  from '../views/meetups/HyderabadMeetups.vue'
import PatnaMeetups      from '../views/meetups/PatnaMeetups.vue'
import ChandigarhMeetups from '../views/meetups/ChandigarhMeetups.vue'
import NotFoundView      from '../views/NotFoundView.vue'

const routes = [
  { path: '/',       component: Home    },
  { path: '/about',  component: About   },
  { path: '/events', component: Events  },
  { path: '/study',  component: Study   },
  { path: '/teams',  component: Teams   },
  { path: '/contact', component: Contact },
  { path: '/login', component: Login   },
  { path: '/lounge',  component: MembersLounge, meta: { requiresAuth: true } },
  { path: '/dashboard', component: DashboardView },

  // Community + sub-pages
  { path: '/community',           component: Community     },
  { path: '/community/technical', component: TechnicalView },
  { path: '/community/cultural',  component: CulturalView  },
  { path: '/community/esports',   component: ESportsView   },

  // Meetups + region sub-pages
  { path: '/meetups',            component: Meetups           },
  { path: '/meetups/delhi-ncr',  component: DelhiNCRMeetups   },
  { path: '/meetups/mumbai',     component: MumbaiMeetups     },
  { path: '/meetups/bangalore',  component: BangaloreMeetups  },
  { path: '/meetups/kolkata',    component: KolkataMeetups    },
  { path: '/meetups/hyderabad',  component: HyderabadMeetups  },
  { path: '/meetups/patna',      component: PatnaMeetups      },
  { path: '/meetups/chandigarh', component: ChandigarhMeetups },

  // 404 catch-all
  { path: '/:pathMatch(.*)*', name: 'NotFound', component: NotFoundView }

]

export const router = createRouter({
  history: createWebHashHistory(),
  routes,
  scrollBehavior(to) {
    if (to.hash) return { el: to.hash, behavior: 'smooth' }
    return { top: 0 }
  },
})

router.beforeEach((to, from, next) => {
  if (to.meta.requiresAuth) {
    const token = localStorage.getItem('sundarbans_auth_token')
    token ? next() : next('/members')
  } else {
    next()
  }
})
