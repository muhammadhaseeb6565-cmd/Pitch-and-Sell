import prisma from '../src/config/prisma';

async function main() {
  console.log('Seeding Pitch and Sell configuration and mock data...');

  // 1. Seed System Configuration
  const configs = [
    { key: 'MAX_VIDEO_DURATION', value: '60' },
    { key: 'PAY_NOW_FEE', value: '20' },
    { key: 'COD_FEE', value: '10' },
    { key: 'MIN_PAYOUT', value: '500' },
    { key: 'FEATURED_PRODUCT_FEE', value: '100' },
    { key: 'DEAL_TRANSACTION_FEE', value: '5' },
  ];

  for (const config of configs) {
    await prisma.systemConfig.upsert({
      where: { key: config.key },
      update: { value: config.value },
      create: config,
    });
  }

  // 2. Create a Mock Seller User
  const seller = await prisma.user.upsert({
    where: { email: 'seller@emulgic.com' },
    update: {},
    create: {
      email: 'seller@emulgic.com',
      name: 'Tahir Pitafi',
      avatarUrl: 'https://lh3.googleusercontent.com/a/mock-seller',
    },
  });

  // 3. Create Seller Business Profile
  const business = await prisma.businessProfile.upsert({
    where: { userId: seller.id },
    update: {},
    create: {
      userId: seller.id,
      name: "Tahir Pitafi's Tech Boutique",
      category: 'Electronics',
      description: 'Primary supplier of premium tech items and development accessories.',
      phone: '+923001234567',
      email: 'tahir@emulgic.com',
      city: 'Lahore',
      address: 'Hafeez Center, Gulberg III',
      status: 'VERIFIED',
    },
  });

  // 4. Create Mock Products & Video details
  const p1 = await prisma.product.create({
    data: {
      businessId: business.id,
      name: 'Super Bass wireless Headphones V2',
      description: 'High-quality wireless headphones with noise cancellations.',
      price: 3500.0,
      oldPrice: 4200.0,
      category: 'Electronics',
      stock: 120,
      status: 'PUBLISHED',
    },
  });

  await prisma.video.create({
    data: {
      productId: p1.id,
      url: 'https://assets.mixkit.co/videos/preview/mixkit-headphones-lying-on-a-laptop-keyboard-4436-large.mp4',
      duration: 12.0,
      allowDownload: true,
    },
  });

  const p2 = await prisma.product.create({
    data: {
      businessId: business.id,
      name: 'Mechanical Gaming Keyboard RGB',
      description: 'Blue switch tactile mechanical keyboard for gamers and coders.',
      price: 5200.0,
      oldPrice: 6000.0,
      category: 'Electronics',
      stock: 45,
      status: 'PUBLISHED',
    },
  });

  await prisma.video.create({
    data: {
      productId: p2.id,
      url: 'https://assets.mixkit.co/videos/preview/mixkit-hands-typing-on-a-mechanical-keyboard-41724-large.mp4',
      duration: 15.0,
      allowDownload: false,
    },
  });

  console.log('Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
