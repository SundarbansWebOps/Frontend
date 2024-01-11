import { mount } from '@vue/test-utils';
import HomePage from '../../src/components/HomePage';

describe('HomePage.vue', () => {
  it('renders without errors', () => {
    const wrapper = mount(HomePage);
    expect(wrapper.exists()).toBe(true);
  });
});