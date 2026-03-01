import type { PluginApi } from '../types.js';

let _api: PluginApi;

export function setApi(api: PluginApi): void {
	_api = api;
}

export function getApi(): PluginApi {
	if (!_api) {
		throw new Error('MeshView API not initialized. Call setApi() first.');
	}
	return _api;
}
