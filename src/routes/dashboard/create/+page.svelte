<script lang="ts">
</script>

<div class="flex flex-1 items-center justify-center p-2">
	<div>
		<div>
			<span class="text-xl font-bold text-black">Choose Listing Type</span>
		</div>
		<div class="mt-4 flex flex-col items-stretch justify-center gap-5 md:flex-row">
			<a
				href="/dashboard/create/wanted"
				class="flex flex-col items-center justify-center rounded-md bg-white p-5 py-8 shadow-sm hover:bg-gray-200 md:max-w-[12rem]"
			>
				<div
					class="flex h-[5rem] w-[5rem] items-center justify-center overflow-hidden rounded-full bg-blue-200"
				>
					<img class="w-[85%]" src="/sale.png" alt="Wanted Listing" />
				</div>
				<div class="mt-2 text-center font-bold text-black">Wanted Listing</div>
				<div class="text-center text-sm text-gray-400">
					Can't find what you're looking for? Create a listing for your desired item or service.
				</div>
			</a>
			<a
				href="/dashboard/create/sale"
				class="flex flex-col items-center justify-center rounded-md bg-white p-5 py-8 shadow-sm hover:bg-gray-200 md:max-w-[12rem]"
			>
				<div
					class="flex h-[5rem] w-[5rem] items-center justify-center overflow-hidden rounded-full bg-orange-200"
				>
					<img class="w-[85%]" src="/shopping.svg" alt="Item for Sale" />
				</div>
				<div class="mt-2 text-center font-bold text-black">Item for Sale</div>
				<div class="text-center text-sm text-gray-400">
					Join the student marketplace and earn cash by selling your items to your peers.
				</div>
			</a>
			<a
				href="/dashboard/create/service"
				class="flex flex-col items-center justify-center rounded-md bg-white p-5 py-8 shadow-sm hover:bg-gray-200 md:max-w-[12rem]"
			>
				<div
					class="flex h-[5rem] w-[5rem] items-center justify-center overflow-hidden rounded-full bg-green-200"
				>
					<img class="w-[85%]" src="/learn.svg" alt="Academic Services" />
				</div>
				<div class="mt-2 text-center font-bold text-black">Academic Services</div>
				<div class="text-center text-sm text-gray-400">
					Earn money sharing your knowledge and passion for academics. Help others succeed!
				</div>
			</a>
		</div>
	</div>
</div>
