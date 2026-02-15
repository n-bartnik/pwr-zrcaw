import axios from 'axios';
import { env } from '$env/dynamic/public';

const api = axios.create({
	baseURL: env.PUBLIC_API_BASE_URL
});

api.interceptors.request.use((config) => {
    return config
})
export default api;
