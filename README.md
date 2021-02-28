# Soundscape Experience Mobile

## Intoduction

Soundscape Experience Mobile has been designed with two main goals: first, to enable navigating soundscapes using a natural, touch-based interface at home or on the go. Second, to allow users to explore soundscapes in an immersive virtual experience delivered in real-world environments. These goals are accomplished by providing two separate interaction modes:
1. Touch-based: users can explore the Soundscape by moving the listener's icon using their finger and can change orientation by rotating the device. The 3D audio simulation is updated in real-time according to the listener's icon current position;
2. AR-based: users explore a soundscape according to their movements in the real-world captured using ARkit. The 3D audio simulation in real-time according to the relative position of the device with respect to the detected ground plane.

Soundscapes can be loaded from the PLUGGY social platform using the QR code reader included in the app or by importing the metadata using Airdrop. The app has also controls for the reverb settings, a button to reset the listener's orientation, play, stop and a button to choose which HRTF should be used.

Spatialisation is performed by the [3DTune-In audio toolkit](https://github.com/3DTune-In).

## Setup

In order to compile and run this project, it is necessary to checkout:
- [3dti AudioToolkit](https://github.com/3DTune-In/3dti_AudioToolkit);
- [cereal serialisation library](http://USCiLab.github.com/cereal).

Both must be checked out in the same root folder as the project. Dependencies must be resolved manually in Xcode's editor (to link sources from the `TIEngine/3DTIFramework` folder of the project).

## Known issues

- Audio rendering performance is degraded when compiling the project in debug configuration. For this reason, the build scheme is pre-configured to build the project in release mode.

## Credits

This application has been developed by the Audio Experience Design team at Imperial College London (http://www.imperial.ac.uk/design-engineering/research/audio-experience-design/) within the EU-funded PLUGGY research project (https://www.pluggy-project.eu/).

PLUGGY provides the instruments needed to create, process and experience 3D soundscapes and sonic narratives without the need for specific devices, external tools (software and/or hardware), specialised knowledge or custom development.