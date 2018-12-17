%%
%%
%%

-module(ebml).

-export([tokens/1]).

%% "EBML" uses a system of "Elements" to compose an "EBML Document".
%% "EBML Elements" incorporate three parts: an "Element ID", an "Element
%% Data Size", and "Element Data".  The "Element Data", which is
%% described by the "Element ID", includes either binary data, one or
%% many other "EBML Elements", or both
%%

-compile({no_auto_import,[element/2]}).

-record(element, {
    name,     % id, or name of element 
    data_size % size of the element
}).

-record(value, {
    type,
    value 
}).

-record(state, {
    data = <<>>
}).

tokens(Bin) ->
    tokens(Bin, #state{}).

tokens(Bin, State) ->
    tokens(Bin, [], State). 

tokens(Bin, Acc, State) ->
    element(Bin, Acc).

element(Bin, Acc) ->
    case element_id(Bin) of
        {error,_}=Error ->
            Error;
        {Id, Rest} ->
            {ElementName, ElementType} = ebml_type(Id),
            case element_data_size(Rest) of
                {error,_}=Error ->
                    Error;
                {DataSize, Rest1} ->
                    Token = #element{name=ElementName, data_size=DataSize},
                    value(ElementType, DataSize, Rest1, [Token|Acc])
            end
    end.

value(master, Size, Bin, Acc) when Size =< size(Bin) ->
    %% we have the data...
    <<Value:Size/binary, Rest/binary>> = Bin,
    Elements = element(Value, []),
    V = #value{type=master, value=Elements},
    element(Rest, [Value | Acc]);

value(Type, Size, Bin, Acc) when Size =< size(Bin) ->
    <<Value:Size/binary, Rest/binary>> = Bin,
    V = #value{type=Type, value=Value},
    element(Rest, [V | Acc]);

value(Type, Size, Bin, Acc)  ->
    % Not enough data
    ok.

element_id(<<16#FF, _Rest/binary>>) -> error;
element_id(<<1:1, N:7, Rest/binary>>) -> {N, Rest};
element_id(<<1:2, N:14, Rest/binary>>) -> {N, Rest};
element_id(<<1:3, N:21, Rest/binary>>) -> {N, Rest};
element_id(<<1:4, N:28, Rest/binary>>) -> {N, Rest};
element_id(_) -> {error, no_element_id}.

element_data_size(<<16#FF, Rest/binary>>) -> {reserved, Rest};
element_data_size(<<1:1, N:7, Rest/binary>>) -> {N, Rest};
element_data_size(<<1:2, N:14, Rest/binary >>) -> {N, Rest};
element_data_size(<<1:3, N:21, Rest/binary>>) -> {N, Rest};
element_data_size(<<1:4, N:28, Rest/binary>>) -> {N, Rest};
element_data_size(<<1:5, N:35, Rest/binary>>) -> {N, Rest};
element_data_size(<<1:6, N:42, Rest/binary>>) -> {N, Rest};
element_data_size(<<1:7, N:49, Rest/binary>>) -> {N, Rest};
element_data_size(<<1:8, N:56, Rest/binary>>) -> {N, Rest};
element_data_size(_) -> {error, no_data_size}.


ebml_type(16#A45DFA3) -> {'EBML', master};
ebml_type(16#286) -> {'EBMLVersion', uinteger};
ebml_type(16#2F7) -> {'EBMLReadVersion', uinteger};
ebml_type(16#2F2) -> {'EBMLMaxIDLength', uinteger};
ebml_type(16#2F3) -> {'EBMLMaxSizeLength', uinteger};
ebml_type(16#282) -> {'DocType', string};
ebml_type(16#287) -> {'DocTypeVersion', uinteger};
ebml_type(16#285) -> {'DocTypeReadVersion', uinteger};
ebml_type(16#281) -> {'DocTypeExtension', master};
ebml_type(16#283) -> {'DocTypeExtensionName', string};
ebml_type(16#284) -> {'DocTypeExtensionVersion', uinteger};
ebml_type(16#3F) -> {'CRC-32', binary};
ebml_type(16#6C) -> {'Void', binary};

%% webm ids stuff
ebml_type(16#8538067) -> {'Segment', master};
ebml_type(16#B538667) -> {'SignatureSlot', master};
ebml_type(16#3E8A) -> {'SignatureAlgo', uinteger};
ebml_type(16#3E9A) -> {'SignatureHash', uinteger};
ebml_type(16#3EA5) -> {'SignaturePublicKey', binary};
ebml_type(16#3EB5) -> {'Signature', binary};
ebml_type(16#3E5B) -> {'SignatureElements', master};
ebml_type(16#3E7B) -> {'SignatureElementList', master};
ebml_type(16#2532) -> {'SignedElement', binary};

ebml_type(16#14D9B74) -> {'SeekHeader', master};
ebml_type(16#DBB) -> {'SeekPoint', master};
ebml_type(16#13AB) -> {'SeekID', binary};
ebml_type(16#13AC) -> {'SeekPosition', uinteger};
ebml_type(16#549A966) -> {'Info', master};
ebml_type(16#33A4) -> {'SegmentUID', binary};
ebml_type(16#3384) -> {'SegmentFilename', 'utf-8'};
ebml_type(16#1CB923) -> {'PrevUID', binary};
ebml_type(16#1C83AB) -> {'PrevFilename', 'utf-8'};
ebml_type(16#1EB923) -> {'NextUID', 'binary'};
ebml_type(16#1E83BB) -> {'NextFilename', 'utf-8'};
ebml_type(16#444) -> {'SegmentFamily', 'binary'};
ebml_type(16#2924) -> {'ChapterTranslate', 'master'};
ebml_type(16#29FC) -> {'ChapterTranslateEditionUID', 'uinteger'};
ebml_type(16#29BF) -> {'ChapterTranslateCodec', 'uinteger'};
ebml_type(16#29A5) -> {'ChapterTranslateID', 'binary'};
ebml_type(16#AD7B1) -> {'TimecodeScale', 'uinteger'};
ebml_type(16#AD7B2) -> {'TimecodeScaleDenominator', 'uinteger'};
ebml_type(16#489) -> {'Duration', 'float'};
ebml_type(16#461) -> {'DateUTC', 'date'};
ebml_type(16#3BA9) -> {'Title', 'utf-8'};
ebml_type(16#D80) -> {'MuxingApp', 'utf-8'};
ebml_type(16#1741) -> {'WritingApp', 'utf-8'};
ebml_type(16#F43B675) -> {'Cluster', 'master'};
ebml_type(16#67) -> {'ClusterTimecode', 'uinteger'};
ebml_type(16#1854) -> {'ClusterSilentTracks', 'master'};
ebml_type(16#18D7) -> {'ClusterSilentTrackNumber', 'uinteger'};
ebml_type(16#27) -> {'ClusterPosition', 'uinteger'};
ebml_type(16#2B) -> {'ClusterPrevSize', 'uinteger'};
ebml_type(16#23) -> {'SimpleBlock', binary};
ebml_type(16#20) -> {'BlockGroup', 'master'};
ebml_type(16#21) -> {'Block', 'binary'};
ebml_type(16#22) -> {'BlockVirtual', 'binary'};
ebml_type(16#35A1) -> {'BlockAdditions', 'master'};
ebml_type(16#26) -> {'BlockMore', 'master'};
ebml_type(16#6E) -> {'BlockAddID', 'uinteger'};
ebml_type(16#25) -> {'BlockAdditional', 'binary'};
ebml_type(16#1B) -> {'BlockDuration', 'uinteger'};
ebml_type(16#7A) -> {'FlagReferenced', 'uinteger'};
ebml_type(16#7B) -> {'ReferenceBlock', 'integer'};
ebml_type(16#7D) -> {'ReferenceVirtual', 'integer'};
ebml_type(16#24) -> {'CodecState', 'binary'};
ebml_type(16#35A2) -> {'DiscardPadding', 'integer'};
ebml_type(16#E) -> {'Slices', 'master'};
ebml_type(16#68) -> {'TimeSlice', 'master'};
ebml_type(16#4C) -> {'SliceLaceNumber', 'uinteger'};
ebml_type(16#4D) -> {'SliceFrameNumber', 'uinteger'};
ebml_type(16#4B) -> {'SliceBlockAddID', 'uinteger'};
ebml_type(16#4E) -> {'SliceDelay', 'uinteger'};
ebml_type(16#4F) -> {'SliceDuration', 'uinteger'};
ebml_type(16#48) -> {'ReferenceFrame', 'master'};
ebml_type(16#49) -> {'ReferenceOffset', 'uinteger'};
ebml_type(16#4A) -> {'ReferenceTimeCode', 'uinteger'};
ebml_type(16#2F) -> {'EncryptedBlock', 'binary'};
ebml_type(16#654AE6B) -> {'Tracks', 'master'};
ebml_type(16#2E) -> {'TrackEntry', 'master'};
ebml_type(16#57) -> {'TrackNumber', 'uinteger'};
ebml_type(16#33C5) -> {'TrackUID', 'uinteger'};
ebml_type(16#3) -> {'TrackType', 'uinteger'};
ebml_type(16#39) -> {'TrackFlagEnabled', 'uinteger'};
ebml_type(16#8) -> {'TrackFlagDefault', 'uinteger'};
ebml_type(16#15AA) -> {'TrackFlagForced', 'uinteger'};
ebml_type(16#1C) -> {'TrackFlagLacing', 'uinteger'};
ebml_type(16#2DE7) -> {'TrackMinCache', 'uinteger'};
ebml_type(16#2DF8) -> {'TrackMaxCache', 'uinteger'};
ebml_type(16#3E383) -> {'TrackDefaultDuration', 'uinteger'};
ebml_type(16#34E7A) -> {'TrackDefaultDecodedFieldDuration', 'uinteger'};
ebml_type(16#3314F) -> {'TrackTimecodeScale', 'float'};
ebml_type(16#137F) -> {'TrackOffset', 'integer'};
ebml_type(16#15EE) -> {'MaxBlockAdditionID', 'uinteger'};
ebml_type(16#136E) -> {'TrackName', 'utf-8'};
ebml_type(16#2B59C) -> {'TrackLanguage', 'string'};
ebml_type(16#6) -> {'CodecID', 'string'};
ebml_type(16#23A2) -> {'CodecPrivate', 'binary'};
ebml_type(16#58688) -> {'CodecName', 'utf-8'};
ebml_type(16#3446) -> {'TrackAttachmentLink', 'uinteger'};
ebml_type(16#1A9697) -> {'CodecSettings', 'utf-8'};
ebml_type(16#1B4040) -> {'CodecInfoURL', 'string'};
ebml_type(16#6B240) -> {'CodecDownloadURL', 'string'};
ebml_type(16#2A) -> {'CodecDecodeAll', 'uinteger'};
ebml_type(16#2FAB) -> {'TrackOverlay', 'uinteger'};
ebml_type(16#16AA) -> {'CodecDelay', 'uinteger'};
ebml_type(16#16BB) -> {'SeekPreRoll', 'uinteger'};
ebml_type(16#2624) -> {'TrackTranslate', 'master'};
ebml_type(16#26FC) -> {'TrackTranslateEditionUID', 'uinteger'};
ebml_type(16#26BF) -> {'TrackTranslateCodec', 'uinteger'};
ebml_type(16#26A5) -> {'TrackTranslateTrackID', 'binary'};
ebml_type(16#60) -> {'TrackVideo', 'master'};
ebml_type(16#1A) -> {'VideoFlagInterlaced', 'uinteger'};
ebml_type(16#13B8) -> {'VideoStereoMode', 'uinteger'};
ebml_type(16#13B9) -> {'OldStereoMode', 'uinteger'};
ebml_type(16#30) -> {'VideoPixelWidth', 'uinteger'};
ebml_type(16#3A) -> {'VideoPixelHeight', 'uinteger'};
ebml_type(16#14AA) -> {'VideoPixelCropBottom', 'uinteger'};
ebml_type(16#14BB) -> {'VideoPixelCropTop', 'uinteger'};
ebml_type(16#14CC) -> {'VideoPixelCropLeft', 'uinteger'};
ebml_type(16#14DD) -> {'VideoPixelCropRight', 'uinteger'};
ebml_type(16#14B0) -> {'VideoDisplayWidth', 'uinteger'};
ebml_type(16#14BA) -> {'VideoDisplayHeight', 'uinteger'};
ebml_type(16#14B2) -> {'VideoDisplayUnit', 'uinteger'};
ebml_type(16#14B3) -> {'VideoAspectRatio', 'uinteger'};
ebml_type(16#EB524) -> {'VideoColourSpace', 'binary'};
ebml_type(16#FB523) -> {'VideoGamma', 'float'};
ebml_type(16#383E3) -> {'VideoFrameRate', 'float'};
ebml_type(16#61) -> {'TrackAudio', 'master'};
ebml_type(16#35) -> {'AudioSamplingFreq', 'float'};
ebml_type(16#38B5) -> {'AudioOutputSamplingFreq', 'float'};
ebml_type(16#1F) -> {'AudioChannels', 'uinteger'};
ebml_type(16#3D7B) -> {'AudioPosition', 'binary'};
ebml_type(16#2264) -> {'AudioBitDepth', 'uinteger'};
ebml_type(16#62) -> {'TrackOperation', 'master'};
ebml_type(16#63) -> {'TrackCombinePlanes', 'master'};
ebml_type(16#64) -> {'TrackPlane', 'master'};
ebml_type(16#65) -> {'TrackPlaneUID', 'uinteger'};
ebml_type(16#66) -> {'TrackPlaneType', 'uinteger'};
ebml_type(16#69) -> {'TrackJoinBlocks', 'master'};
ebml_type(16#6D) -> {'TrackJoinUID', 'uinteger'};
ebml_type(16#40) -> {'TrickTrackUID', 'uinteger'};
ebml_type(16#41) -> {'TrickTrackSegmentUID', 'binary'};
ebml_type(16#46) -> {'TrickTrackFlag', 'uinteger'};
ebml_type(16#47) -> {'TrickMasterTrackUID', 'uinteger'};
ebml_type(16#44) -> {'TrickMasterTrackSegmentUID', 'binary'};
ebml_type(16#2D80) -> {'ContentEncodings', 'master'};
ebml_type(16#2240) -> {'ContentEncoding', 'master'};
ebml_type(16#1031) -> {'ContentEncodingOrder', 'uinteger'};
ebml_type(16#1032) -> {'ContentEncodingScope', 'uinteger'};
ebml_type(16#1033) -> {'ContentEncodingType', 'uinteger'};
ebml_type(16#1034) -> {'ContentCompression', 'master'};
ebml_type(16#254) -> {'ContentCompAlgo', 'uinteger'};
ebml_type(16#255) -> {'ContentCompSettings', 'binary'};
ebml_type(16#1035) -> {'ContentEncryption', 'master'};
ebml_type(16#7E1) -> {'ContentEncAlgo', 'uinteger'};
ebml_type(16#7E2) -> {'ContentEncKeyID', 'binary'};
ebml_type(16#7E3) -> {'ContentSignature', 'binary'};
ebml_type(16#7E4) -> {'ContentSigKeyID', 'binary'};
ebml_type(16#7E5) -> {'ContentSigAlgo', 'uinteger'};
ebml_type(16#7E6) -> {'ContentSigHashAlgo', 'uinteger'};
ebml_type(16#C53BB6B) -> {'Cues', 'master'};
ebml_type(16#3B) -> {'CuePoint', 'master'};
ebml_type(16#33) -> {'CueTime', 'uinteger'};
ebml_type(16#37) -> {'CueTrackPositions', 'master'};
ebml_type(16#77) -> {'CueTrack', 'uinteger'};
ebml_type(16#71) -> {'CueClusterPosition', 'uinteger'};
ebml_type(16#70) -> {'CueRelativePosition', 'uinteger'};
ebml_type(16#32) -> {'CueDuration', 'uinteger'};
ebml_type(16#1378) -> {'CueBlockNumber', 'uinteger'};
ebml_type(16#6A) -> {'CueCodecState', 'uinteger'};
ebml_type(16#5B) -> {'CueReference', 'master'};
ebml_type(16#16) -> {'CueRefTime', 'uinteger'};
ebml_type(16#17) -> {'CueRefCluster', 'uinteger'};
ebml_type(16#135F) -> {'CueRefNumber', 'uinteger'};
ebml_type(16#6B) -> {'CueRefCodecState', 'uinteger'};
ebml_type(16#941A469) -> {'Attachments', 'master'};
ebml_type(16#21A7) -> {'AttachedFile', 'master'};
ebml_type(16#67E) -> {'FileDescription', 'utf-8'};
ebml_type(16#66E) -> {'FileName', 'utf-8'};
ebml_type(16#660) -> {'FileMimeType', 'string'};
ebml_type(16#65C) -> {'FileData', 'binary'};
ebml_type(16#6AE) -> {'FileUID', 'uinteger'};
ebml_type(16#675) -> {'FileReferral', 'binary'};
ebml_type(16#661) -> {'FileUsedStartTime', 'uinteger'};
ebml_type(16#662) -> {'FileUsedEndTime', 'uinteger'};
ebml_type(16#43A770) -> {'Chapters', 'master'};
ebml_type(16#5B9) -> {'EditionEntry', 'master'};
ebml_type(16#5BC) -> {'EditionUID', 'uinteger'};
ebml_type(16#5BD) -> {'EditionFlagHidden', 'uinteger'};
ebml_type(16#5DB) -> {'EditionFlagDefault', 'uinteger'};
ebml_type(16#5DD) -> {'EditionFlagOrdered', 'uinteger'};
ebml_type(16#36) -> {'ChapterAtom', 'master'};
ebml_type(16#33C4) -> {'ChapterUID', 'uinteger'};
ebml_type(16#1654) -> {'ChapterStringUID', 'utf-8'};
ebml_type(16#11) -> {'ChapterTimeStart', 'uinteger'};
ebml_type(16#12) -> {'ChapterTimeEnd', 'uinteger'};
ebml_type(16#18) -> {'ChapterFlagHidden', 'uinteger'};
ebml_type(16#598) -> {'ChapterFlagEnabled', 'uinteger'};
ebml_type(16#2E67) -> {'ChapterSegmentUID', 'binary'};
ebml_type(16#2EBC) -> {'ChapterSegmentEditionUID', 'uinteger'};
ebml_type(16#23C3) -> {'ChapterPhysicalEquiv', 'uinteger'};
ebml_type(16#F) -> {'ChapterTrack', 'master'};
ebml_type(16#9) -> {'ChapterTrackNumber', 'uinteger'};
ebml_type(16#0) -> {'ChapterDisplay', 'master'};
ebml_type(16#5) -> {'ChapterString', 'utf-8'};
ebml_type(16#37C) -> {'ChapterLanguage', 'string'};
ebml_type(16#37E) -> {'ChapterCountry', 'string'};
ebml_type(16#2944) -> {'ChapterProcess', 'master'};
ebml_type(16#2955) -> {'ChapterProcessCodecID', 'uinteger'};
ebml_type(16#50D) -> {'ChapterProcessPrivate', 'binary'};
ebml_type(16#2911) -> {'ChapterProcessCommand', 'master'};
ebml_type(16#2922) -> {'ChapterProcessTime', 'uinteger'};
ebml_type(16#2933) -> {'ChapterProcessData', 'binary'};
ebml_type(16#254C367) -> {'Tags', 'master'};
ebml_type(16#3373) -> {'Tag', 'master'};
ebml_type(16#23C0) -> {'TagTargets', 'master'};
ebml_type(16#28CA) -> {'TagTargetTypeValue', 'uinteger'};
ebml_type(16#23CA) -> {'TagTargetType', 'string'};
ebml_type(16#23C5) -> {'TagTrackUID', 'uinteger'};
ebml_type(16#23C9) -> {'TagEditionUID', 'uinteger'};
ebml_type(16#23C4) -> {'TagChapterUID', 'uinteger'};
ebml_type(16#23C6) -> {'TagAttachmentUID', 'uinteger'};
ebml_type(16#27C8) -> {'TagSimple', 'master'};
ebml_type(16#5A3) -> {'TagName', 'utf-8'};
ebml_type(16#47A) -> {'TagLanguage', 'string'};
ebml_type(16#484) -> {'TagDefault', 'uinteger'};
ebml_type(16#487) -> {'TagString', 'utf-8'};
ebml_type(16#485) -> {'TagBinary', 'binary'};


ebml_type(Id) -> {Id, unknown}.



