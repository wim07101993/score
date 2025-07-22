//osmd.TransposeCalculator = new opensheetmusicdisplay.TransposeCalculator(); // needs OSMD 1.0.0+, better 1.3.0+
function handleFileSelect(evt) {
    const osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("musicxml-score");
    const file = evt.target.files[0];

    if (!file.name.match('.*\.xml') && !file.name.match('.*\.musicxml') && !file.name.match('.*\.mxl')) {
        alert('You selected a non-xml file. Please select only music xml files.');
        return;
    }

    const reader = new FileReader();
    reader.onload = function (e) {
        osmd.load(e.target.result).then(
            function () {
                //console.log("e.target.result: " + e.target.result);
                // osmd.sheet.Transpose = 1;
                osmd.render();
            }
        );
    };
    if (file.name.match('.*\.mxl')) {
        // have to read as binary, otherwise JSZip will throw ("corrupted zip: missing 37 bytes" or similar)
        reader.readAsBinaryString(file);
    } else {
        reader.readAsText(file);
    }
}

document.getElementById("file-input").addEventListener("change", handleFileSelect, false);