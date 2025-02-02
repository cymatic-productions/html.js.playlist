$(document).ready(function() {
    $("#generate").click(function() {
        var title = $("#title").val();
        var artist = $("#artist").val();
        var genre = $("#genre").val();
        var mood = $("#mood").val();
        var tempo = $("#tempo").val();
        var key = $("#key").val();
        var instruments = $("#instruments").val();
        var keywords = $("#keywords").val();
        var visuals = $("#visuals").val();
        var lyrics = $("#lyrics").val();

        var vibeSummary = 
            `🎶 **Vibe Summary**: The track "${title}" by ${artist} is a ${mood} ${genre} piece with a ${tempo} tempo and key ${key}. ` +
            `Featuring ${instruments}, the sound feels ${keywords}. The inspiration is drawn from ${visuals}. ${lyrics ? "The lyrics/themes suggest: " + lyrics : ""}`;

        var aiArtPrompt = 
            `🎨 **AI Art Prompt**: A highly detailed digital artwork inspired by the ${mood} tone of "${title}". ` +
            `Featuring elements of ${keywords}, the visuals take cues from ${visuals}. The color scheme should reflect the mood, incorporating textures from ${instruments}.`;

        var imageDescription = 
            `📝 **Descriptive Text for Iteration**: The generated image should convey a sense of ${mood}, ` +
            `blending ${keywords} elements with ${visuals}. Look for atmospheric details that reflect the musical essence.`;

        var storyboardText = 
            `📜 **Storyboard Scene**: The opening scene sets the tone of the video by incorporating ${keywords} aesthetics. ` +
            `The landscape evolves in sync with the ${tempo} beat of "${title}". The colors transition from ${mood}-themed shades to a cinematic visual journey.`;

        var editingSuggestions = 
            `🎬 **Editing Suggestions**: The final video should emphasize the track's ${mood} feel, using smooth transitions and pacing that syncs with the ${tempo}. ` +
            `Consider enhancing the visuals with ${visuals}-inspired overlays for extra impact.`;

        $("#output").html(`
            <h2>🎼 AI-Generated Prompts</h2>
            <p>${vibeSummary}</p>
            <p>${aiArtPrompt}</p>
            <p>${imageDescription}</p>
            <p>${storyboardText}</p>
            <p>${editingSuggestions}</p>
        `);
    });
});
