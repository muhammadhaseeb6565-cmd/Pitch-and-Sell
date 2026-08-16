import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Ensure uploads directories exist
const uploadDirs = ['uploads/videos', 'uploads/logos', 'uploads/products'];
uploadDirs.forEach((dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let dest = 'uploads/';
    if (file.fieldname === 'video') {
      dest = 'uploads/videos/';
    } else if (file.fieldname === 'logo') {
      dest = 'uploads/logos/';
    } else {
      dest = 'uploads/products/';
    }
    cb(null, dest);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  },
});

const fileFilter = (req: any, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
  const allowedVideoTypes = /mp4|mov|avi|mkv|webm|quicktime/;
  const allowedImageTypes = /jpeg|jpg|png|webp|gif/;

  const ext = path.extname(file.originalname).toLowerCase();
  const mimetype = file.mimetype;

  if (file.fieldname === 'video') {
    const isVideo = allowedVideoTypes.test(ext) || mimetype.startsWith('video/');
    if (isVideo) {
      return cb(null, true);
    }
    return cb(new Error('Only video files are allowed for video upload!'));
  } else {
    const isImage = allowedImageTypes.test(ext) || mimetype.startsWith('image/');
    if (isImage) {
      return cb(null, true);
    }
    return cb(new Error('Only image files are allowed for logos and product pictures!'));
  }
};

export const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100 MB max file size
  },
});
