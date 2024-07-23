import { mount } from '@vue/test-utils';
import CouncilPage from '../../src/components/CouncilPage.vue';

describe('CouncilPage.vue', () => {
  it('renders without errors', () => {
    const wrapper = mount(CouncilPage);
    expect(wrapper.exists()).toBe(true);
  });

  it('renders the correct title for Upper House Council Representatives', () => {
    const wrapper = mount(CouncilPage);
    const upperHouseTitle = wrapper.find('h1.text-2xl');
    expect(upperHouseTitle.text()).toBe('Upper House Council Representatives');
  });
});
