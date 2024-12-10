function play(audioSrc) {
    const audioPlayer = document.getElementById('audioPlayer');
    audioPlayer.src = audioSrc;
    audioPlayer.play();
}

function playCymatic(mp3Name) {
    play(`https://github.com/cymatic-productions/mixcraft.${mp3Name}/raw/master/${mp3Name}.mp3`)
}

function playArchived(mp3Name) {
    play(`https://github.com/cymatic-productions/archived-audio/raw/master/${mp3Name}.mp3`)
}


function setupAutoplay() {
    const audioPlayer = document.getElementById('audioPlayer');
    const playlistButtons = Array.from(document.querySelectorAll('.playlist button'));

    // Play a specific song by index
    function playTrackByIndex(index) {
        if (index >= 0 && index < playlistButtons.length) {
            const songButton = playlistButtons[index];
            const songId = songButton.getAttribute('id');
            const songName = songButton.getAttribute('onclick').match(/'([^']+)'/)[1]; // Extract the song name
            playCymatic(songName); // Call playCymatic to play the song
            highlightCurrentSong(songId); // Optional: Highlight the current song
        }
    }

    // Play the next track
    function playNextTrack() {
        const currentSongIndex = playlistButtons.findIndex(button =>
            button.classList.contains('playing')
        );
        if (currentSongIndex !== -1 && currentSongIndex + 1 < playlistButtons.length) {
            playTrackByIndex(currentSongIndex + 1);
        }
    }

    // Highlight the current playing song (optional)
    function highlightCurrentSong(songId) {
        playlistButtons.forEach(button => button.classList.remove('playing'));
        const currentButton = document.getElementById(songId);
        if (currentButton) currentButton.classList.add('playing');
    }

    // Add event listener to the audio player
    audioPlayer.addEventListener('ended', playNextTrack);

    // Add click listeners to playlist buttons
    playlistButtons.forEach(button => {
        button.addEventListener('click', () => {
            const index = playlistButtons.indexOf(button);
            playTrackByIndex(index);
        });
    });
}
