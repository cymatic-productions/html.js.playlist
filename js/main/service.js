import MediaPlayer from './MediaPlayer.js';

const mediaPlayer = new MediaPlayer('videoPlayer', 'audioPlayer', '.container');

function play(baseName) {    
    mediaPlayer.onplay(baseName);
}

function playCymatic(mp3Name) {
    play(`https://github.com/cymatic-productions/mixcraft.${mp3Name}/raw/master/${mp3Name}`)
}

function playArchived(mp3Name) {
    play(`https://github.com/cymatic-productions/archived-audio/raw/master/${mp3Name}`)
}

// Update setupAutoplay to use MediaPlayer
function setupAutoplay() {
    const playlistButtons = Array.from(document.querySelectorAll('.playlist button'));

    function playTrackByIndex(index) {
        if (index >= 0 && index < playlistButtons.length) {
            const songButton = playlistButtons[index];
            const songId = songButton.getAttribute('id');
            const songName = songButton.getAttribute('onclick').match(/'([^']+)'/)[1];
            playCymatic(songName);
            highlightCurrentSong(songId);
        }
    }

    function playNextTrack() {
        const currentSongIndex = playlistButtons.findIndex(button =>
            button.classList.contains('playing')
        );
        if (currentSongIndex !== -1 && currentSongIndex + 1 < playlistButtons.length) {
            playTrackByIndex(currentSongIndex + 1);
        }
    }

    function highlightCurrentSong(songId) {
        playlistButtons.forEach(button => button.classList.remove('playing'));
        const currentButton = document.getElementById(songId);
        if (currentButton) currentButton.classList.add('playing');
    }

    mediaPlayer.videoPlayer.addEventListener('ended', playNextTrack);
    mediaPlayer.audioPlayer.addEventListener('ended', playNextTrack);

    playlistButtons.forEach(button => {
        button.addEventListener('click', () => {
            const index = playlistButtons.indexOf(button);
            playTrackByIndex(index);
        });
    });
}



// Attach to the window object
window.playCymatic = playCymatic;
window.playArchived = playArchived;
window.setupAutoplay = setupAutoplay;
window.play = play;