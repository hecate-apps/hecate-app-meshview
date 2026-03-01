<svelte:options customElement={{ tag: "meshview-studio", shadow: "none" }} />

<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import type { PluginApi, HealthData, MeshSnapshot } from './types.js';
	import { setApi } from './shared/api.js';
	import MeshStatus from './mesh_status/MeshStatus.svelte';

	let { api }: { api: PluginApi } = $props();

	let health: HealthData | null = $state(null);
	let meshSnapshot: MeshSnapshot | null = $state(null);
	let connectionStatus: 'connected' | 'connecting' | 'disconnected' = $state('connecting');
	let pollTimer: ReturnType<typeof setInterval> | undefined;

	onMount(() => {
		setApi(api);
		pollHealth();
		pollTimer = setInterval(pollHealth, 5000);
	});

	onDestroy(() => {
		if (pollTimer) clearInterval(pollTimer);
	});

	async function pollHealth() {
		try {
			health = await api.get<HealthData>('/health');
			connectionStatus = health?.ok ? 'connected' : 'disconnected';

			if (connectionStatus === 'connected') {
				meshSnapshot = await api.get<MeshSnapshot>('/api/mesh/status');
			}
		} catch {
			connectionStatus = 'disconnected';
			health = null;
			meshSnapshot = null;
		}
	}

	let statusColor = $derived(
		connectionStatus === 'connected' ? 'bg-success-500'
		: connectionStatus === 'connecting' ? 'bg-warning-500'
		: 'bg-danger-500'
	);
</script>

<div class="flex flex-col h-full bg-surface-900 text-surface-100 p-4">
	<!-- Header -->
	<div class="flex items-center justify-between mb-6">
		<div class="flex items-center gap-3">
			<span class="text-2xl">🌐</span>
			<div>
				<h1 class="text-lg font-bold">MeshView</h1>
				<p class="text-xs text-surface-500">Macula Mesh Observer</p>
			</div>
		</div>
		<div class="flex items-center gap-2">
			<span class="inline-block w-2 h-2 rounded-full {statusColor}"></span>
			<span class="text-xs text-surface-400">
				{#if health}
					v{health.version}
				{:else}
					{connectionStatus}
				{/if}
			</span>
		</div>
	</div>

	<!-- Content -->
	{#if connectionStatus === 'disconnected'}
		<div class="flex-1 flex items-center justify-center">
			<div class="text-center">
				<p class="text-surface-400">MeshView daemon not reachable</p>
				<p class="text-xs text-surface-600 mt-1">Ensure hecate-app-meshviewd is running</p>
			</div>
		</div>
	{:else}
		<MeshStatus snapshot={meshSnapshot} />
	{/if}
</div>
