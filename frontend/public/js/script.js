document.addEventListener('DOMContentLoaded', () => {
  const navLinks = document.querySelectorAll('.nav-link');
  const views = document.querySelectorAll('.view');

  function activateView(target) {
    views.forEach((view) => {
      view.classList.toggle('active', view.dataset.view === target);
    });
    navLinks.forEach((link) => {
      link.classList.toggle('active', link.dataset.target === target);
    });
  }

  navLinks.forEach((link) => {
    link.addEventListener('click', () => {
      activateView(link.dataset.target);
    });
  });
});
