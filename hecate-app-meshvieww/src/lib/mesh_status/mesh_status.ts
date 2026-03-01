import { getApi } from '../shared/api.js';
import type { MeshSnapshot } from '../types.js';

/** Reactive mesh status state */
export let meshSnapshot: MeshSnapshot | null = $state(null);
export let isLoading = $state(false);
export let meshError: string | null = $state(null);

/** Fetch the latest mesh status snapshot */
export async function fetchMeshStatus(): Promise<void> {
	isLoading = true;
	meshError = null;
	try {
		const api = getApi();
		const data = await api.get<MeshSnapshot>('/api/mesh/status');
		meshSnapshot = data;
	} catch (err) {
		meshError = err instanceof Error ? err.message : 'Failed to fetch mesh status';
	} finally {
		isLoading = false;
	}
}
