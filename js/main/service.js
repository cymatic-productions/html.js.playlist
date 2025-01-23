function play(baseName) {
    const videoPlayer = document.getElementById('videoPlayer');
    const audioPlayer = document.getElementById('audioPlayer');

    const mp4Src = `${baseName}.mp4`;
    const mp3Src = `${baseName}.mp3`;

    // Hide both players initially and stop them
    videoPlayer.style.display = 'none';
    audioPlayer.style.display = 'none';
    videoPlayer.pause();
    audioPlayer.pause();

    // Reset the sources for both players
    videoPlayer.src = '';
    audioPlayer.src = '';

    // Try to play the MP4 in the video player
    videoPlayer.src = mp4Src;
    videoPlayer.load();

    videoPlayer.oncanplay = () => {
        videoPlayer.style.display = 'block'; // Show the video player if MP4 loads successfully
        videoPlayer.play();
        
        audioPlayer.style.display = 'none';
        audioPlayer.pause();
    };

    videoPlayer.onerror = () => {
        // Fallback to MP3 if MP4 fails
        audioPlayer.src = mp3Src;
        audioPlayer.style.display = 'block'; // Show the audio player
        audioPlayer.play();

        videoPlayer.style.display = 'none'; // Show the video player if MP4 loads successfully
        videoPlayer.pause();
    };

    videoPlayer.play().catch(() => {
        // Fallback if play() fails (e.g., browser policy restrictions)
        videoPlayer.onerror();
    });
}

function playCymatic(mp3Name) {
    play(`https://github.com/cymatic-productions/mixcraft.${mp3Name}/raw/master/${mp3Name}`)
}

function playArchived(mp3Name) {
    play(`https://github.com/cymatic-productions/archived-audio/raw/master/${mp3Name}`)
}


function setupAutoplay() {
    const videoPlayer = document.getElementById('videoPlayer');
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

    // Add event listeners to handle media ending
    videoPlayer.addEventListener('ended', playNextTrack);
    audioPlayer.addEventListener('ended', playNextTrack);

    // Add click listeners to playlist buttons
    playlistButtons.forEach(button => {
        button.addEventListener('click', () => {
            const index = playlistButtons.indexOf(button);
            playTrackByIndex(index);
        });
    });
}