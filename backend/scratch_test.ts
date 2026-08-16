import prisma from './src/config/prisma';

async function test() {
  try {
    console.log("Fetching seed user...");
    const user = await prisma.user.findFirst();
    if (!user) {
      console.log("No user found!");
      return;
    }
    console.log("Found user:", user.email);
    
    // Mock login using native fetch to /api/auth/google
    const loginRes = await fetch('http://localhost:5000/api/auth/google', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: user.email,
        name: user.name,
        avatarUrl: user.avatarUrl || ''
      })
    });
    
    const loginData = await loginRes.json() as any;
    const token = loginData.token;
    console.log("Logged in! Token:", token ? "Token received" : "No token");
    
    // Call feed
    const feedRes = await fetch('http://localhost:5000/api/products/feed', {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    const feedData = await feedRes.json() as any;
    if (feedRes.status !== 200) {
      console.error("Feed error details:", feedData);
    } else {
      console.log("Feed fetched successfully!");
      console.log("Products count:", feedData.products?.length);
      console.log("First product details:", JSON.stringify(feedData.products?.[0], null, 2));
    }
  } catch (err: any) {
    console.error("Test failed with error:", err.message);
  }
}

test();
