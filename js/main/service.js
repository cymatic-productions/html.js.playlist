function play(audioSrc) {
    const audioPlayer = document.getElementById('audioPlayer');
    audioPlayer.src = audioSrc;
    audioPlayer.play();
}

function playCymatic(mp3Name) {
    play(`https://github.com/cymatic-productions/mixcraft.${mp3Name}/raw/master/${mp3Name}.mp3`)
}
