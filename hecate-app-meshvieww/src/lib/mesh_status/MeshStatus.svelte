<script lang="ts">
	import type { MeshSnapshot } from '../types.js';

	let { snapshot }: { snapshot: MeshSnapshot | null } = $props();

	let daemonStatus = $derived(
		snapshot?.daemon_connected ? 'Connected' : 'Disconnected'
	);
	let meshStatus = $derived(
		snapshot?.mesh_connected ? 'Connected' : 'Disconnected'
	);
	let daemonColor = $derived(
		snapshot?.daemon_connected ? 'text-success-400' : 'text-danger-400'
	);
	let meshColor = $derived(
		snapshot?.mesh_connected ? 'text-success-400' : 'text-danger-400'
	);
</script>

<div class="space-y-4">
	<!-- Daemon Connection -->
	<div class="rounded-lg bg-surface-800 p-4">
		<div class="flex items-center justify-between">
			<span class="text-sm text-surface-400">Daemon</span>
			<span class="text-sm font-medium {daemonColor}">{daemonStatus}</span>
		</div>
		{#if snapshot?.daemon_node}
			<p class="mt-1 text-xs text-surface-500">{snapshot.daemon_node}</p>
		{/if}
	</div>

	<!-- Mesh Connection -->
	<div class="rounded-lg bg-surface-800 p-4">
		<div class="flex items-center justify-between">
			<span class="text-sm text-surface-400">Mesh</span>
			<span class="text-sm font-medium {meshColor}">{meshStatus}</span>
		</div>
		{#if snapshot?.node_id}
			<p class="mt-1 text-xs text-surface-500 break-all">Node: {snapshot.node_id}</p>
		{/if}
	</div>

	<!-- Peers -->
	<div class="rounded-lg bg-surface-800 p-4">
		<div class="flex items-center justify-between">
			<span class="text-sm text-surface-400">Peers</span>
			<span class="text-sm font-medium text-accent-400">{snapshot?.peer_count ?? 0}</span>
		</div>
		{#if snapshot?.peers && snapshot.peers.length > 0}
			<ul class="mt-2 space-y-1">
				{#each snapshot.peers as peer}
					<li class="text-xs text-surface-500 break-all">
						{peer.node_id ?? peer.address ?? JSON.stringify(peer)}
					</li>
				{/each}
			</ul>
		{:else if snapshot?.mesh_connected}
			<p class="mt-1 text-xs text-surface-600">No peers discovered yet</p>
		{/if}
	</div>

	<!-- Last Poll -->
	{#if snapshot?.last_poll}
		<p class="text-xs text-surface-600 text-right">
			Last updated: {new Date(snapshot.last_poll).toLocaleTimeString()}
		</p>
	{/if}
</div>
