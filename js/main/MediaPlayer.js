export default class MediaPlayer {
    constructor(videoPlayerId, audioPlayerId, containerSelector) {
        this.videoPlayer = document.getElementById(videoPlayerId);
        this.audioPlayer = document.getElementById(audioPlayerId);
        this.container = document.querySelector(containerSelector);

        this.resetMedia();
    }

    resetMedia() {
        this.videoPlayer.style.display = 'none';
        this.audioPlayer.style.display = 'none';
        this.videoPlayer.pause();
        this.audioPlayer.pause();
        this.videoPlayer.src = '';
        this.audioPlayer.src = '';

        const existingGif = this.container.querySelector('.gif-player');
        if (existingGif) {
            this.container.removeChild(existingGif);
        }
    }

    onplay(baseName) {
        const mp4Src = `${baseName}.mp4`;
        const mp3Src = `${baseName}.mp3`;
        const gifSrc = `${baseName}.gif`;

        this.resetMedia();

        this.videoPlayer.src = mp4Src;
        this.videoPlayer.muted = true;
        this.videoPlayer.load();

        this.videoPlayer.oncanplay = () => {
            this.audioPlayer.src = mp3Src;
            this.audioPlayer.load();

            this.audioPlayer.oncanplay = () => {
                this.videoPlayer.style.display = 'block';
                this.audioPlayer.style.display = 'block';
                this.videoPlayer.play();
                this.audioPlayer.play();
            };

            this.audioPlayer.onerror = () => {
                this.videoPlayer.muted = false;
                this.videoPlayer.play();
            };
        };

        this.videoPlayer.onerror = () => {
            this.handleGifAndMp3Fallback(mp3Src, gifSrc);
        };
    }

    handleGifAndMp3Fallback(mp3Src, gifSrc) {
        const gif = document.createElement('img');
        gif.src = gifSrc;
        gif.alt = 'GIF fallback';
        gif.className = 'gif-player';
        gif.style.width = '100%';
        gif.style.borderRadius = '8px';
        gif.style.marginBottom = '20px';

        gif.onload = () => {
            this.container.insertBefore(gif, this.videoPlayer);
            this.audioPlayer.src = mp3Src;
            this.audioPlayer.style.display = 'block';
            this.audioPlayer.play();
        };

        gif.onerror = () => {
            this.audioPlayer.src = mp3Src;
            this.audioPlayer.style.display = 'block';
            this.audioPlayer.play();
        };
    }

    onerror(errorCallback) {
        this.videoPlayer.onerror = () => errorCallback('Video failed to load');
        this.audioPlayer.onerror = () => errorCallback('Audio failed to load');
    }
}
