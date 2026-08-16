import { Request, Response } from 'express';

export const generatePitchScript = async (req: Request, res: Response) => {
  try {
    const { productName, sellingPoint, tone, language } = req.body;

    if (!productName || !sellingPoint) {
      return res.status(400).json({ error: 'Product name and selling points are required' });
    }

    const scripts: Record<string, Record<string, string>> = {
      en: {
        professional: `[0:00 - 0:05]\n"Looking for premium quality? Meet the new ${productName}. Crafted for professionals who demand excellence."\n\n[0:05 - 0:10]\n"Featuring our industry-leading ${sellingPoint}. It delivers unmatched performance you can rely on daily."\n\n[0:10 - 0:15]\n"Wholesale slots are open now. Tap 'Order Now' to view current offers and start your order today."`,
        exciting: `[0:00 - 0:05]\n"Get ready to level up! This is the ultimate ${productName} you've been waiting for!"\n\n[0:05 - 0:10]\n"With absolute game-changing ${sellingPoint}, experience performance like never before!"\n\n[0:10 - 0:15]\n"Limited wholesale batch is selling fast! Double tap to like, and tap 'Order Now' to grab yours!"`,
      },
      ur: {
        professional: `[0:00 - 0:05]\n"Kya aap behtareen quality ki talash me hain? Paish hai naya ${productName}. Jo banaya gaya hai aapki sahulat ke liye."\n\n[0:05 - 0:10]\n"Isme shamil hai specialized ${sellingPoint}, jo deta hai flawless performance har waqt."\n\n[0:10 - 0:15]\n"Wholesale slots active hain. Abhi 'Order Now' par click karein aur apna batch booking start karein."`,
        exciting: `[0:00 - 0:05]\n"Dosto, taiyar ho jayein! Aa gaya hai market ka sabse behtareen ${productName}!"\n\n[0:05 - 0:10]\n"Iske super fast ${sellingPoint} ke sath, ab quality hogi next level par!"\n\n[0:10 - 0:15]\n"Wholesale stock limited hai! Jaldi se 'Order Now' par click karein aur offer accept karein!"`,
      }
    };

    const selectedLang = language === 'ur' ? 'ur' : 'en';
    const selectedTone = tone === 'professional' ? 'professional' : 'exciting';

    const script = scripts[selectedLang][selectedTone];

    res.status(200).json({
      success: true,
      script,
      tips: [
        'Keep your camera at eye level while recording.',
        'Speak clearly and maintain high energy.',
        'Ensure the product is well-lit and in focus.'
      ]
    });
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to generate pitch script', details: error.message });
  }
};
