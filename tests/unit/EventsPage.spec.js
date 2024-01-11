import { mount } from '@vue/test-utils';
import EventsPage from '../../src/components/EventsPage';

describe('EventsPage.vue', () => {
  it('renders without errors', () => {
    const wrapper = mount(EventsPage);
    expect(wrapper.exists()).toBe(true);
  });
});
