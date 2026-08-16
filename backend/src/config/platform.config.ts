import prisma from './prisma';

const DEFAULT_CONFIGS: Record<string, string> = {
  MAX_VIDEO_DURATION: '60',
  PAY_NOW_FEE: '20',
  COD_FEE: '10',
  MIN_PAYOUT: '500',
  FEATURED_PRODUCT_FEE: '100',
  DEAL_TRANSACTION_FEE: '5',
};

export const getConfigValue = async (key: string): Promise<number> => {
  try {
    const config = await prisma.systemConfig.findUnique({
      where: { key },
    });

    if (config) {
      return parseFloat(config.value);
    }
  } catch (error) {
    console.warn(`Failed to fetch system config for key: ${key}. Using default fallback.`);
  }

  // Fallback to default configs
  const val = DEFAULT_CONFIGS[key];
  return val ? parseFloat(val) : 0;
};

export const setConfigValue = async (key: string, value: string): Promise<void> => {
  await prisma.systemConfig.upsert({
    where: { key },
    update: { value },
    create: { key, value },
  });
};
