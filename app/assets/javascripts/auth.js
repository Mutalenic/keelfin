function initAuthPasswordToggle() {
  const toggles = document.querySelectorAll('[data-toggle-password]');

  toggles.forEach((toggle) => {
    const inputId = toggle.getAttribute('data-toggle-password');
    const input = document.getElementById(inputId);
    const icon = toggle.querySelector('i');

    if (!input || !icon) {
      return;
    }

    toggle.addEventListener('click', () => {
      const isPassword = input.type === 'password';
      input.type = isPassword ? 'text' : 'password';
      icon.className = isPassword ? 'fa-solid fa-eye-slash text-sm' : 'fa-solid fa-eye text-sm';
    });
  });
}

document.addEventListener('DOMContentLoaded', initAuthPasswordToggle);
document.addEventListener('turbo:load', initAuthPasswordToggle);
