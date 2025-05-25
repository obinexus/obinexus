import { createRouter } from './router';
import './styles/main.scss';

const app = document.getElementById('app');

if (app) {
  const router = createRouter();
  router.start(app);
}
