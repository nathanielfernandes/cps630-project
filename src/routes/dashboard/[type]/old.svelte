<script>
	import Card from '$lib/components/Card.svelte';

	let ads = [
		{
			id: 1,
			title: 'MTH 140 Textbook',
			description: 'I am looking for Calculus: Early Transcendentals by James Stewart.',
			date: '2024-01-02',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?textbook&cb=1'],
			user: 'David Smith'
		},
		{
			id: 2,
			title: 'Graphing Calculator',
			description: 'Looking for graphing calculator, preferably texas instruments.',
			date: '2023-12-10',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?calculator&cb=2'],
			user: 'Anna Johnson'
		},
		{
			id: 3,
			title: 'Chemistry Lab Equpiment',
			description: "I am looking for a women's medium lab coat and safety goggles.",
			date: '2024-01-13',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?lab,coat&cb=3'],
			user: 'Mina Kim'
		},
		{
			id: 4,
			title: 'Graduation Cap and Gown',
			description: 'Looking for a graduation cap and gown ASAP.',
			date: '2023-12-01',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?graduation,gown&cb=4'],
			user: 'Aaron Lee'
		},
		{
			id: 5,
			title: 'Art Supplies',
			description: 'I am looking for a set of watercolor paints and brushes.',
			date: '2024-01-25',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?paint&cb=5'],
			user: 'Liz Jouri'
		},
		{
			id: 6,
			title: 'Model for Fashion Design Class',
			description:
				'I am looking for someone to model the clothing pieces I have made for my fashion course.',
			date: '2024-02-20',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?mannequin,fashion&cb=6'],
			user: 'Rebecca Heath'
		},
		{
			id: 7,
			title: 'Compound Microscope',
			description: 'Looking for a microscope for my biology class.',
			date: '2023-11-05',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?microscope&cb=7'],
			user: 'Arthur Read'
		},
		{
			id: 8,
			title: 'MPC 103 - Art History Textbook',
			description: 'I am looking for Art History: A Very Short Introduction by Dana Arnold.',
			date: '2024-03-04',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?textbook,art&cb=8'],
			user: 'Mia Warren'
		},
		{
			id: 9,
			title: 'Soldering Iron',
			description: 'Looking for a soldering iron in good condition.',
			date: '2023-12-27',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?welding&cb=9'],
			user: 'Ella Sheridan'
		},
		{
			id: 10,
			title: 'Apple Pencil',
			description: 'Looking to buy a brand new apple pencil.',
			date: '2024-03-15',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?applepencil&cb=10'],
			user: 'Omar Ahmad'
		},
		{
			id: 11,
			title: 'Desk and Chair',
			description: 'I am looking for a small desk and chair, IKEA brand works.',
			date: '2024-01-09',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?desk,chair&cb=11'],
			user: 'Dylan Sanders'
		},
		{
			id: 12,
			title: 'Monitor',
			description: 'Looking for a monitor, 27" and larger.',
			date: '2023-2-18',
			price: 0,
			profile_image: '',
			images: ['https://source.unsplash.com/random/350x250?monitor&cb=12'],
			user: 'Sabrina Green'
		}
	];

	const backgroundColours = ['2dbcda', '1bd4ab', '5d28e7', 'e44141', 'e4419f', 'ff6f2f'];

	ads.forEach((ad) => {
		const initials = ad.user
			.split(' ')
			.map((word) => word[0])
			.join('');
		const randomColor = backgroundColours[Math.floor(Math.random() * backgroundColours.length)];
		ad.profile_image = `https://api.dicebear.com/7.x/initials/svg?seed=${initials}&scale=90&backgroundColor=${randomColor}&radius=20`;
		ad.price = Math.floor(Math.random() * 200);
	});
</script>

<div
	class="xs:grid-cols-1 mx-auto mb-10 mt-10 grid w-full max-w-screen-xl gap-10 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
>
	{#each ads as ad}
		<Card
			title={ad.title}
			description={ad.description}
			date={ad.date}
			price={ad.price}
			profile_image={ad.profile_image}
			images={ad.images}
			user={ad.user}
		/>
	{/each}
</div>
