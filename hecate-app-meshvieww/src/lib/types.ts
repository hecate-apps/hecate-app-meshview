/** Plugin API interface provided by hecate-web host */
export interface PluginApi {
	get: <T>(path: string) => Promise<T>;
	post: <T>(path: string, body: unknown) => Promise<T>;
	del: <T>(path: string) => Promise<T>;
}

/** Health check response from meshviewd */
export interface HealthData {
	ok: boolean;
	app: string;
	version: string;
	node: string;
}

/** Mesh status snapshot from mesh_observer */
export interface MeshSnapshot {
	ok: boolean;
	daemon_connected: boolean;
	mesh_connected: boolean;
	daemon_node: string | null;
	node_id: string | null;
	peer_count: number;
	peers: MeshPeer[];
	last_poll: number | null;
}

/** A peer on the mesh network */
export interface MeshPeer {
	node_id?: string;
	address?: string;
	[key: string]: unknown;
}
