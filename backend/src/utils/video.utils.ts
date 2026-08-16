import ffmpeg from 'fluent-ffmpeg';

export const getVideoDuration = (filePath: string): Promise<number> => {
  return new Promise((resolve, reject) => {
    ffmpeg.ffprobe(filePath, (err, metadata) => {
      if (err) {
        console.warn('ffprobe warning: Failed to fetch video metadata (is ffmpeg installed?). Falling back to mock duration.', err);
        // Fallback: Mock a safe duration of 15 seconds so developers without ffmpeg installed locally are not blocked.
        return resolve(15.0);
      }
      const duration = metadata?.format?.duration;
      if (duration === undefined) {
        return resolve(15.0);
      }
      resolve(duration);
    });
  });
};
