{ ****************************************************************************** }
{ * AI Support                                                                 * }
{ * by QQ 600585@qq.com                                                        * }
{ ****************************************************************************** }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ * https://github.com/PassByYou888/zGameWare                                  * }
{ * https://github.com/PassByYou888/zRasterization                             * }
{ ****************************************************************************** }
unit zAI;

{$INCLUDE zDefine.inc}

(* cuda-nvcc compatible record packing *)
{$IFDEF FPC}
{$PACKENUM 4}    (* use 4-byte enums *)
{$PACKRECORDS C}
{$ELSE}
{$MINENUMSIZE 4} (* use 4-byte enums *)
{$ENDIF}

interface

uses Types,
  CoreClasses,
{$IFDEF FPC}
  FPCGenericStructlist,
{$ELSE FPC}
  System.IOUtils,
{$ENDIF FPC}
  PascalStrings, MemoryStream64, UnicodeMixedLib, DataFrameEngine, ZDBEngine, ZDBLocalManager, ObjectDataManager, ObjectData, ItemStream,
  zDrawEngine, ListEngine, Geometry2DUnit, MemoryRaster, LearnTypes, Learn, KDTree, PyramidSpace, zAI_Common, zAI_KeyIO;

type
  TAI_DetectorDefine = class;
  TAI_Image = class;
  TAI_ImageList = class;
  TAI = class;

{$IFDEF FPC}
  TImageList_Decl = specialize TGenericsList<TAI_Image>;
  TDetectorDefineList = specialize TGenericsList<TAI_DetectorDefine>;
{$ELSE FPC}
  TImageList_Decl = TGenericsObjectList<TAI_Image>;
  TDetectorDefineList = TGenericsObjectList<TAI_DetectorDefine>;
{$ENDIF FPC}

  TAI_DetectorDefine = class(TCoreClassObject)
  public
    Owner: TAI_Image;
    R: TRect;
    Token: TPascalString;
    Part: TVec2List;
    PrepareRaster: TMemoryRaster;

    constructor Create(AOwner: TAI_Image);
    destructor Destroy; override;

    procedure SaveToStream(stream: TMemoryStream64);
    procedure LoadFromStream(stream: TMemoryStream64);
  end;

  TAI_Image = class(TCoreClassObject)
  public
    Owner: TAI_ImageList;
    DetectorDefineList: TDetectorDefineList;
    Raster: TMemoryRaster;

    constructor Create(AOwner: TAI_ImageList);
    destructor Destroy; override;

    procedure Clear;
    procedure ClearPrepareRaster;

    procedure DrawTo(output: TMemoryRaster);

    function FoundNoTokenDetectorDefine(output: TMemoryRaster; color: TDEColor): Boolean; overload;
    function FoundNoTokenDetectorDefine: Boolean; overload;

    procedure SaveToStream(stream: TMemoryStream64; SaveImg: Boolean);
    procedure LoadFromStream(stream: TMemoryStream64; LoadImg: Boolean);
    procedure LoadPicture(fileName: SystemString);

    procedure Scale(f: TGeoFloat);

    function ExistsToken(Token: TPascalString): Boolean;
    function GetTokenCount(Token: TPascalString): Integer;
  end;

  TAI_ImageList = class(TImageList_Decl)
  public
    FileInfo: TPascalString;
    UserData: TCoreClassObject;

    constructor Create;
    destructor Destroy; override;

    procedure Delete(index: Integer);

    procedure Clear;
    procedure ClearPrepareRaster;

    procedure DrawTo(output: TMemoryRaster);

    procedure AddPicture(stream: TCoreClassStream); overload;
    procedure AddPicture(fileName: SystemString); overload;
    procedure AddPicture(R: TMemoryRaster); overload;

    procedure LoadFromPictureStream(stream: TCoreClassStream);
    procedure LoadFromPictureFile(fileName: SystemString);

    function PackingRaster: TMemoryRaster;
    procedure SaveToPictureStream(stream: TCoreClassStream);
    procedure SaveToPictureFile(fileName: SystemString);

    procedure SavePrepareRasterToPictureStream(stream: TCoreClassStream);
    procedure SavePrepareRasterToPictureFile(fileName: SystemString);

    procedure SaveToStream(stream: TCoreClassStream; SaveImg, Compressed: Boolean);
    procedure LoadFromStream(stream: TCoreClassStream; LoadImg: Boolean); overload;
    procedure LoadFromStream(stream: TCoreClassStream); overload;

    procedure SaveToFile(fileName: SystemString);
    procedure LoadFromFile(fileName: SystemString; LoadImg: Boolean); overload;
    procedure LoadFromFile(fileName: SystemString); overload;

    procedure Import(imgList: TAI_ImageList);

    procedure CalibrationNullDetectorDefineToken(Token: SystemString);
    procedure CalibrationDetectorDefineTokenPrefix(Prefix: SystemString);
    procedure CalibrationDetectorDefineTokenSuffix(Suffix: SystemString);

    procedure Scale(f: TGeoFloat);

    procedure Build_PrepareDataset(outputPath: SystemString);
    procedure Build_XML(TokenFilter: TPascalString; includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList); overload;
    procedure Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList); overload;
    procedure Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file: SystemString); overload;

    function DetectorDefineCount: Integer;
    function DetectorDefinePartCount: Integer;

    function ExtractDetectorDefineAsSnapshot: TMemoryRaster2DArray;
    function ExtractDetectorDefineAsPrepareRaster(SS_width, SS_height: Integer): TMemoryRaster2DArray;
    function ExtractDetectorDefineAsScaleSpace(SS_width, SS_height: Integer): TMemoryRaster2DArray;

    function FoundNoTokenDetectorDefine(output: TMemoryRaster): Boolean; overload;
    function FoundNoTokenDetectorDefine: Boolean; overload;

    function Tokens: TArrayPascalString;

    function ExistsToken(Token: TPascalString): Boolean;
    function GetTokenCount(Token: TPascalString): Integer;
  end;

{$IFDEF FPC}

  TAI_ImageMatrix_Decl = specialize TGenericsList<TAI_ImageList>;
{$ELSE FPC}
  TAI_ImageMatrix_Decl = TGenericsObjectList<TAI_ImageList>;
{$ENDIF FPC}

  TAI_ImageMatrix = class(TAI_ImageMatrix_Decl)
  public
    constructor Create;
    destructor Destroy; override;

    procedure SaveToStream(stream: TCoreClassStream);
    procedure LoadFromStream(stream: TCoreClassStream);

    procedure SaveToFile(fileName: SystemString);
    procedure LoadFromFile(fileName: SystemString);

    procedure ClearPrepareRaster;

    procedure SearchAndAddImageList(rootPath, filter: SystemString; includeSubdir, LoadImg: Boolean);

    procedure Scale(f: TGeoFloat);

    procedure Build_PrepareDataset(outputPath: SystemString);
    procedure Build_XML(TokenFilter: TPascalString; includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList); overload;
    procedure Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList); overload;
    procedure Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file: SystemString); overload;

    function ImageCount: Integer;
    function DetectorDefineCount: Integer;
    function DetectorDefinePartCount: Integer;

    function ExtractDetectorDefineAsSnapshot: TMemoryRaster2DArray;
    function ExtractDetectorDefineAsPrepareRaster(SS_width, SS_height: Integer): TMemoryRaster2DArray;
    function ExtractDetectorDefineAsScaleSpace(SS_width, SS_height: Integer): TMemoryRaster2DArray;

    function FoundNoTokenDetectorDefine(output: TMemoryRaster): Boolean; overload;
    function FoundNoTokenDetectorDefine: Boolean; overload;

    function Tokens: TArrayPascalString;
    function ExistsToken(Token: TPascalString): Boolean;
    function GetTokenCount(Token: TPascalString): Integer;
  end;

{$REGION 'BaseDefine'}

  PAI_Entry = ^TAI_Entry;

  TRGB_Image_Handle = Pointer;
  TMatrix_Image_Handle = Pointer;
  TOD_Handle = Pointer;
  TOD_Marshal_Handle = THashList;
  TSP_Handle = Pointer;
  TFACE_Handle = Pointer;
  TMDNN_Handle = Pointer;
  TMMOD_Handle = Pointer;
  TRNIC_Handle = Pointer;
  TTracker_Handle = Pointer;

  PSurf_Desc = ^TSurf_Desc;

  TSurf_Desc = packed record
    x, y, dx, dy: Integer;
    desc: array [0 .. 63] of Single;
  end;

  TSurf_DescBuffer = array of TSurf_Desc;

  PSurfMatched = ^TSurfMatched;

  TSurfMatched = record
    sd1, sd2: PSurf_Desc;
    r1, r2: TMemoryRaster;
  end;

  TSurfMatchedBuffer = array of TSurfMatched;

  P_Bytes = ^C_Bytes;

  C_Bytes = packed record
    Size: Integer;
    Bytes: PByte;
  end;

  PAI_Rect = ^TAI_Rect;

  TAI_Rect = packed record
    Left, Top, Right, Bottom: Integer;
  end;

  TOD_Desc = array of TAI_Rect;

  TOD_Marshal_Rect = record
    R: TRectV2;
    Token: TPascalString;
  end;

  TOD_Marshal_Desc = array of TOD_Marshal_Rect;

{$IFDEF FPC}
  TOD_List_Decl = specialize TGenericsList<TAI_Rect>;
  TOD_Marshal_List_Decl = specialize TGenericsList<TOD_Marshal_Rect>;
{$ELSE FPC}
  TOD_List_Decl = TGenericsList<TAI_Rect>;
  TOD_Marshal_List_Decl = TGenericsList<TOD_Marshal_Rect>;
{$ENDIF FPC}
  TOD_List = TOD_List_Decl;

  TOD_Marshal_List = TOD_Marshal_List_Decl;

  PAI_Point = ^TAI_Point;

  TAI_Point = packed record
    x, y: Integer;
  end;

  TSP_Desc = array of TAI_Point;

  PTrainingControl = ^TTrainingControl;

  TTrainingControl = packed record
    pause, stop: Integer;
  end;

  PAI_MMOD_Rect = ^TAI_MMOD_Rect;

  TAI_MMOD_Rect = packed record
    Left, Top, Right, Bottom: Integer;
    Token: PPascalString;
  end;

  TAI_MMOD_Desc = array of TAI_MMOD_Rect;

  TMMOD_Rect = record
    R: TRectV2;
    Token: TPascalString;
  end;

  TMMOD_Desc = array of TMMOD_Rect;

  TAI_Raster_Data = packed record
    raster_ptr: PRasterColorArray;
    width, height, index: Integer;
  end;

  PAI_Raster_Data = ^TAI_Raster_Data;

  TAI_Raster_Data_Array = array [0 .. (MaxInt div SizeOf(PAI_Raster_Data)) - 1] of PAI_Raster_Data;
  PAI_Raster_Data_Array = ^TAI_Raster_Data_Array;

  TMetric_ResNet_Train_Parameter = packed record
    // input
    imgArry_ptr: PAI_Raster_Data_Array;
    img_num: Integer;
    train_sync_file, train_output: P_Bytes;
    // train param
    timeout: UInt64;
    weight_decay, momentum: Single;
    iterations_without_progress_threshold: Integer;
    learning_rate, completed_learning_rate: Double;
    step_mini_batch_target_num, step_mini_batch_raster_num: Integer;
    // progress control
    control: PTrainingControl;
    // training result
    training_average_loss, training_learning_rate: Double;
    // full gpu
    fullGPU_Training: Boolean;
  end;

  PMetric_ResNet_Train_Parameter = ^TMetric_ResNet_Train_Parameter;

  TMMOD_Train_Parameter = packed record
    // input data
    train_cfg, train_sync_file, train_output: P_Bytes;
    // train param
    timeout: UInt64;
    target_size, min_target_size: Integer;
    min_detector_window_overlap_iou: Double;
    iterations_without_progress_threshold: Integer;
    learning_rate, completed_learning_rate: Double;
    // cropper param
    num_crops: Integer;
    chip_dims_x, chip_dims_y: Integer;
    min_object_size_x, min_object_size_y: Integer;
    max_rotation_degrees, max_object_size: Double;
    // progress control
    control: PTrainingControl;
    // training result
    training_average_loss, training_learning_rate: Double;
    // internal
    TempFiles: TPascalStringList;
  end;

  PMMOD_Train_Parameter = ^TMMOD_Train_Parameter;

  TRNIC_Train_Parameter = packed record
    // input data
    imgArry_ptr: PAI_Raster_Data_Array;
    img_num: Integer;
    train_sync_file, train_output: P_Bytes;
    // train param
    timeout: UInt64;
    weight_decay, momentum: Double;
    iterations_without_progress_threshold: Integer;
    learning_rate, completed_learning_rate: Double;
    all_bn_running_stats_window_sizes: Integer;
    img_mini_batch: Integer;
    // progress control
    control: PTrainingControl;
    // training result
    training_average_loss, training_learning_rate: Double;
  end;

  PRNIC_Train_Parameter = ^TRNIC_Train_Parameter;

  TOneStep = packed record
    StepTime: TDateTime;
    one_step_calls: UInt64;
    average_loss: Double;
    learning_rate: Double;
  end;

  POneStep = ^TOneStep;

  TAI_Log = record
    LogTime: TDateTime;
    LogText: SystemString;
  end;

{$IFDEF FPC}

  TOneStepList_Decl = specialize TGenericsList<POneStep>;
  TAI_LogList_Decl = specialize TGenericsList<TAI_Log>;
{$ELSE FPC}
  TOneStepList_Decl = TGenericsList<POneStep>;
  TAI_LogList_Decl = TGenericsList<TAI_Log>;
{$ENDIF FPC}

  TOneStepList = class(TOneStepList_Decl)
  private
    Critical: TSoftCritical;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Delete(index: Integer);
    procedure Clear;
    procedure AddStep(one_step_calls: UInt64; average_loss, learning_rate: Double);

    procedure SaveToStream(stream: TMemoryStream64);
    procedure LoadFromStream(stream: TMemoryStream64);
  end;

  TAI_LogList = class(TAI_LogList_Decl)
  end;

  TAlignment = class(TCoreClassObject)
  public
    AI: TAI;
    constructor Create(OwnerAI: TAI); virtual;
    destructor Destroy; override;

    procedure Alignment(imgList: TAI_ImageList); virtual; abstract;
  end;

  TAlignment_Face = class(TAlignment)
  public
    procedure Alignment(imgList: TAI_ImageList); override;
  end;

  TAlignment_FastFace = class(TAlignment)
  public
    procedure Alignment(imgList: TAI_ImageList); override;
  end;

  TAlignment_ScaleSpace = class(TAlignment)
  public
    SS_width, SS_height: Integer;
    procedure Alignment(imgList: TAI_ImageList); override;
  end;

  TAlignment_OD = class(TAlignment)
  public
    od_hnd: TOD_Handle;
    procedure Alignment(imgList: TAI_ImageList); override;
  end;

  TAlignment_FastOD = class(TAlignment)
  public
    od_hnd: TOD_Handle;
    procedure Alignment(imgList: TAI_ImageList); override;
  end;

  TAlignment_OD_Marshal = class(TAlignment)
  public
    od_hnd: TOD_Marshal_Handle;
    procedure Alignment(imgList: TAI_ImageList); override;
  end;

  TAlignment_FastOD_Marshal = class(TAlignment)
  public
    od_hnd: TOD_Marshal_Handle;
    procedure Alignment(imgList: TAI_ImageList); override;
  end;

  TAlignment_SP = class(TAlignment)
  public
    sp_hnd: TSP_Handle;
    procedure Alignment(imgList: TAI_ImageList); override;
  end;

  TAlignment_MMOD = class(TAlignment)
  public
    MMOD_hnd: TMMOD_Handle;
    procedure Alignment(imgList: TAI_ImageList); override;
  end;

  TAlignment_FastMMOD = class(TAlignment)
  public
    MMOD_hnd: TMMOD_Handle;
    procedure Alignment(imgList: TAI_ImageList); override;
  end;

  TAI_Parallel = class;

  TAI_Entry = packed record
    // prepare image
    Prepare_RGB_Image: function(const raster_ptr: PRasterColorArray; const width, height: Integer): TRGB_Image_Handle; stdcall;
    Prepare_Matrix_Image: function(const raster_ptr: PRasterColorArray; const width, height: Integer): TMatrix_Image_Handle; stdcall;
    Close_RGB_Image: procedure(img: TRGB_Image_Handle); stdcall;
    Close_Matrix_Image: procedure(img: TMatrix_Image_Handle); stdcall;

    // surf detector
    fast_surf: function(const raster_ptr: PRasterColorArray; const width, height: Integer;
      const max_points: Integer; const detection_threshold: Double; const output: PSurf_Desc): Integer; stdcall;

    // object detector
    OD_Train: function(train_cfg, train_output: P_Bytes; window_w, window_h, thread_num: Integer): Integer; stdcall;
    OD_Init: function(train_data: P_Bytes): TOD_Handle; stdcall;
    OD_Init_Memory: function(memory: Pointer; Size: Integer): TOD_Handle; stdcall;
    OD_Free: function(hnd: TOD_Handle): Integer; stdcall;
    OD_Process: function(hnd: TOD_Handle; const raster_ptr: PRasterColorArray; const width, height: Integer;
      const AI_Rect: PAI_Rect; const max_AI_Rect: Integer; var AI_Rect_num: Integer): Integer; stdcall;
    OD_Process_Image: function(hnd: TOD_Handle; rgb_img: TRGB_Image_Handle;
      const AI_Rect: PAI_Rect; const max_AI_Rect: Integer; var AI_Rect_num: Integer): Integer; stdcall;

    // shape predictor and shape detector
    SP_Train: function(train_cfg, train_output: P_Bytes; oversampling_amount, tree_depth, thread_num: Integer): Integer; stdcall;
    SP_Init: function(train_data: P_Bytes): TSP_Handle; stdcall;
    SP_Init_Memory: function(memory: Pointer; Size: Integer): TSP_Handle; stdcall;
    SP_Free: function(hnd: TSP_Handle): Integer; stdcall;
    SP_Process: function(hnd: TSP_Handle; const raster_ptr: PRasterColorArray; const width, height: Integer;
      const AI_Rect: PAI_Rect; const AI_Point: PAI_Point; const max_AI_Point: Integer; var AI_Point_num: Integer): Integer; stdcall;
    SP_Process_Image: function(hnd: TSP_Handle; rgb_img: TRGB_Image_Handle;
      const AI_Rect: PAI_Rect; const AI_Point: PAI_Point; const max_AI_Point: Integer; var AI_Point_num: Integer): Integer; stdcall;

    // face recognition shape predictor
    SP_extract_face_rect_desc_chips: function(hnd: TSP_Handle; const raster_ptr: PRasterColorArray; const width, height, extract_face_size: Integer; rect_desc_: PAI_Rect; rect_num: Integer): TFACE_Handle; stdcall;
    SP_extract_face_rect_chips: function(hnd: TSP_Handle; const raster_ptr: PRasterColorArray; const width, height, extract_face_size: Integer): TFACE_Handle; stdcall;
    SP_extract_face_rect: function(const raster_ptr: PRasterColorArray; const width, height: Integer): TFACE_Handle; stdcall;
    SP_close_face_chips_handle: procedure(hnd: TFACE_Handle); stdcall;
    SP_get_face_chips_num: function(hnd: TFACE_Handle): Integer; stdcall;
    SP_get_face_chips_size: procedure(hnd: TFACE_Handle; const index: Integer; var width, height: Integer); stdcall;
    SP_get_face_chips_bits: procedure(hnd: TFACE_Handle; const index: Integer; const raster_ptr: PRasterColorArray); stdcall;
    SP_get_face_rect_num: function(hnd: TFACE_Handle): Integer; stdcall;
    SP_get_face_rect: procedure(hnd: TFACE_Handle; const index: Integer; var AI_Rect: TAI_Rect); stdcall;
    SP_get_num: function(hnd: TFACE_Handle): Integer; stdcall;
    SP_get: function(hnd: TFACE_Handle; const index: Integer; const AI_Point: PAI_Point; const max_AI_Point: Integer): Integer; stdcall;

    // MDNN-ResNet(ResNet matric DNN)
    MDNN_ResNet_Train: function(param: PMetric_ResNet_Train_Parameter): Integer; stdcall;
    MDNN_ResNet_Full_GPU_Train: function(param: PMetric_ResNet_Train_Parameter): Integer; stdcall;
    MDNN_ResNet_Init: function(train_data: P_Bytes): TMDNN_Handle; stdcall;
    MDNN_ResNet_Init_Memory: function(memory: Pointer; Size: Integer): TMDNN_Handle; stdcall;
    MDNN_ResNet_Free: function(hnd: TMDNN_Handle): Integer; stdcall;
    MDNN_ResNet_Process: function(hnd: TMDNN_Handle; imgArry_ptr: PAI_Raster_Data_Array; img_num: Integer; output: PDouble): Integer; stdcall;
    MDNN_DebugInfo: procedure(hnd: TMDNN_Handle; var p: PPascalString); stdcall;

    // MMOD-DNN(max-margin DNN object detector)
    MMOD_DNN_Train: function(param: PMMOD_Train_Parameter): Integer; stdcall;
    MMOD_DNN_Init: function(train_data: P_Bytes): TMMOD_Handle; stdcall;
    MMOD_DNN_Init_Memory: function(memory: Pointer; Size: Integer): TMMOD_Handle; stdcall;
    MMOD_DNN_Free: function(hnd: TMMOD_Handle): Integer; stdcall;
    MMOD_DNN_Process: function(hnd: TMMOD_Handle; const raster_ptr: PRasterColorArray; const width, height: Integer;
      const MMOD_AI_Rect: PAI_MMOD_Rect; const max_AI_Rect: Integer): Integer; stdcall;
    MMOD_DNN_Process_Image: function(hnd: TMMOD_Handle; matrix_img: TMatrix_Image_Handle;
      const MMOD_AI_Rect: PAI_MMOD_Rect; const max_AI_Rect: Integer): Integer; stdcall;
    MMOD_DebugInfo: procedure(hnd: TMMOD_Handle; var p: PPascalString); stdcall;

    // ResNet-Image-Classifier
    RNIC_Train: function(param: PRNIC_Train_Parameter): Integer; stdcall;
    RNIC_Init: function(train_data: P_Bytes): TRNIC_Handle; stdcall;
    RNIC_Init_Memory: function(memory: Pointer; Size: Integer): TRNIC_Handle; stdcall;
    RNIC_Free: function(hnd: TRNIC_Handle): Integer; stdcall;
    RNIC_Process: function(hnd: TRNIC_Handle; const raster_ptr: PRasterColorArray; const width, height: Integer; output: PDouble): Integer; stdcall;
    RNIC_DebugInfo: procedure(hnd: TRNIC_Handle; var p: PPascalString); stdcall;

    // video tracker
    Start_Tracker: function(rgb_img: TRGB_Image_Handle; AI_Rect: PAI_Rect): TTracker_Handle; stdcall;
    Update_Tracker: function(hnd: TTracker_Handle; rgb_img: TRGB_Image_Handle; var AI_Rect: TAI_Rect): Double; stdcall;
    Stop_Tracker: function(hnd: TTracker_Handle): Integer; stdcall;

    // check key
    CheckKey: function(): Integer; stdcall;
    // close ai entry
    CloseAI: procedure(); stdcall;

    // backcall api
    API_OnOneStep: procedure(Sender: PAI_Entry; one_step_calls: UInt64; average_loss, learning_rate: Double); stdcall;
    API_OnPause: procedure(); stdcall;
    API_Status_Out: procedure(Sender: PAI_Entry; i_char: Integer); stdcall;
    API_GetTimeTick64: function(): UInt64; stdcall;
    API_BuildString: function(p: Pointer; Size: Integer): Pointer; stdcall;
    API_FreeString: procedure(p: Pointer); stdcall;

    // version information
    MajorVer, MinorVer: Integer;
    // Key information
    Key: TAI_Key;

    // internal
    LibraryFile: TPascalString;
    LoadLibraryTime: TDateTime;
    OneStepList: TOneStepList;
    Log: TAI_LogList;
  end;

{$ENDREGION 'BaseDefine'}

  TAI = class(TCoreClassObject)
  protected
    // internal
    AI_Ptr: PAI_Entry;
    face_sp_hnd: TSP_Handle;
    TrainingControl: TTrainingControl;
    Critical: TSoftCritical;
  public
    // parallel handle
    Parallel_OD_Hnd: TOD_Handle;
    Parallel_OD_Marshal_Hnd: TOD_Marshal_Handle;
    Parallel_SP_Hnd: TSP_Handle;
    Parallel_MDNN_Hnd: TMDNN_Handle;
    Parallel_MMOD_Hnd: TMMOD_Handle;
    Parallel_RNIC_Hnd: TRNIC_Handle;

    // root path
    rootPath: SystemString;

    // deep neural network training state
    Last_training_average_loss, Last_training_learning_rate: Double;

    constructor Create;
    class function OpenEngine(libFile: SystemString): TAI; overload;
    class function OpenEngine(lib_p: Pointer): TAI; overload;
    class function OpenEngine: TAI; overload;
    destructor Destroy; override;

    // structor draw
    procedure DrawOD(od_hnd: TOD_Handle; Raster: TMemoryRaster; color: TDEColor);
    procedure DrawODM(odm_hnd: TOD_Marshal_Handle; Raster: TMemoryRaster; color: TDEColor);
    procedure DrawSP(od_hnd: TOD_Handle; sp_hnd: TSP_Handle; Raster: TMemoryRaster);
    function DrawMMOD(MMOD_hnd: TMMOD_Handle; Raster: TMemoryRaster; color: TDEColor): TMMOD_Desc;
    procedure DrawFace(Raster: TMemoryRaster);
    function DrawExtractFace(Raster: TMemoryRaster): TMemoryRaster;

    // atomic lock ctrl
    procedure Lock;
    procedure Unlock;
    function Busy: Boolean;

    // training control
    procedure Training_Stop;
    procedure Training_Pause;
    procedure Training_Continue;

    // prepare image
    function Prepare_RGB_Image(Raster: TMemoryRaster): TRGB_Image_Handle;
    procedure Close_RGB_Image(hnd: TRGB_Image_Handle);
    function Prepare_Matrix_Image(Raster: TMemoryRaster): TMatrix_Image_Handle;
    procedure Close_Matrix_Image(hnd: TMatrix_Image_Handle);

    // surf
    function fast_surf(Raster: TMemoryRaster; const max_points: Integer; const detection_threshold: Double): TSurf_DescBuffer;
    function surf_sqr(const sour, dest: PSurf_Desc): Single; inline;
    function Surf_Matched(reject_ratio_sqr: Single; r1_, r2_: TMemoryRaster; sd1_, sd2_: TSurf_DescBuffer): TSurfMatchedBuffer;
    procedure BuildFeatureView(Raster: TMemoryRaster; descbuff: TSurf_DescBuffer);
    function BuildMatchInfoView(var MatchInfo: TSurfMatchedBuffer): TMemoryRaster;
    function BuildSurfMatchOutput(raster1, raster2: TMemoryRaster): TMemoryRaster;

    // object detector
    function OD_Train(train_cfg, train_output: TPascalString; window_w, window_h, thread_num: Integer): Boolean; overload;
    function OD_Train(imgList: TAI_ImageList; TokenFilter, train_output: TPascalString; window_w, window_h, thread_num: Integer): Boolean; overload;
    function OD_Train(imgMat: TAI_ImageMatrix; TokenFilter, train_output: TPascalString; window_w, window_h, thread_num: Integer): Boolean; overload;
    function OD_Train_Stream(imgList: TAI_ImageList; window_w, window_h, thread_num: Integer): TMemoryStream64;
    function OD_Open(train_file: TPascalString): TOD_Handle;
    function OD_Open_Stream(stream: TMemoryStream64): TOD_Handle; overload;
    function OD_Open_Stream(train_file: TPascalString): TOD_Handle; overload;
    function OD_Close(var hnd: TOD_Handle): Boolean;
    function OD_Process(hnd: TOD_Handle; Raster: TMemoryRaster; const max_AI_Rect: Integer): TOD_Desc; overload;
    function OD_Process(hnd: TOD_Handle; Raster: TMemoryRaster): TOD_List; overload;
    procedure OD_Process(hnd: TOD_Handle; Raster: TMemoryRaster; output: TOD_List); overload;
    function OD_Process(hnd: TOD_Handle; rgb_img: TRGB_Image_Handle; const max_AI_Rect: Integer): TOD_Desc; overload;

    // object marshal detector
    function OD_Marshal_Train(imgList: TAI_ImageList; window_w, window_h, thread_num: Integer): TMemoryStream64; overload;
    function OD_Marshal_Train(imgMat: TAI_ImageMatrix; window_w, window_h, thread_num: Integer): TMemoryStream64; overload;
    function OD_Marshal_Open_Stream(stream: TMemoryStream64): TOD_Marshal_Handle; overload;
    function OD_Marshal_Open_Stream(train_file: TPascalString): TOD_Marshal_Handle; overload;
    function OD_Marshal_Close(var hnd: TOD_Marshal_Handle): Boolean;
    function OD_Marshal_Process(hnd: TOD_Marshal_Handle; Raster: TMemoryRaster): TOD_Marshal_Desc;

    // shape predictor and shape detector
    function SP_Train(train_cfg, train_output: TPascalString; oversampling_amount, tree_depth, thread_num: Integer): Boolean; overload;
    function SP_Train(imgList: TAI_ImageList; train_output: TPascalString; oversampling_amount, tree_depth, thread_num: Integer): Boolean; overload;
    function SP_Train(imgMat: TAI_ImageMatrix; train_output: TPascalString; oversampling_amount, tree_depth, thread_num: Integer): Boolean; overload;
    function SP_Train_Stream(imgList: TAI_ImageList; oversampling_amount, tree_depth, thread_num: Integer): TMemoryStream64;
    function SP_Open(train_file: TPascalString): TSP_Handle;
    function SP_Open_Stream(stream: TMemoryStream64): TSP_Handle; overload;
    function SP_Open_Stream(train_file: TPascalString): TSP_Handle; overload;
    function SP_Close(var hnd: TSP_Handle): Boolean;
    function SP_Process(hnd: TSP_Handle; Raster: TMemoryRaster; const AI_Rect: TAI_Rect; const max_AI_Point: Integer): TSP_Desc;
    function SP_Process_Vec2List(hnd: TSP_Handle; Raster: TMemoryRaster; const R: TRectV2): TVec2List;
    function SP_Process_Vec2(hnd: TSP_Handle; Raster: TMemoryRaster; const R: TRectV2): TArrayVec2; overload;
    function SP_Process_Vec2(hnd: TSP_Handle; Raster: TMemoryRaster; const R: TAI_Rect): TArrayVec2; overload;

    // face shape
    procedure PrepareFaceDataSource;
    function Face_Detector(Raster: TMemoryRaster; R: TRect; extract_face_size: Integer): TFACE_Handle; overload;
    function Face_Detector(Raster: TMemoryRaster; desc: TOD_Desc; extract_face_size: Integer): TFACE_Handle; overload;
    function Face_Detector(Raster: TMemoryRaster; mmod_desc: TMMOD_Desc; extract_face_size: Integer): TFACE_Handle; overload;
    function Face_DetectorAsChips(Raster: TMemoryRaster; desc: TAI_Rect; extract_face_size: Integer): TMemoryRaster;
    function Face_Detector_All(Raster: TMemoryRaster): TFACE_Handle; overload;
    function Face_Detector_All(Raster: TMemoryRaster; extract_face_size: Integer): TFACE_Handle; overload;
    function Face_Detector_Rect(Raster: TMemoryRaster): TFACE_Handle;
    function Face_Detector_AllRect(Raster: TMemoryRaster): TOD_Desc;
    function Face_chips_num(hnd: TFACE_Handle): Integer;
    function Face_chips(hnd: TFACE_Handle; index: Integer): TMemoryRaster;
    function Face_Rect_Num(hnd: TFACE_Handle): Integer;
    function Face_Rect(hnd: TFACE_Handle; index: Integer): TAI_Rect;
    function Face_RectV2(hnd: TFACE_Handle; index: Integer): TRectV2;
    function Face_Shape_num(hnd: TFACE_Handle): Integer;
    function Face_Shape(hnd: TFACE_Handle; index: Integer): TSP_Desc;
    function Face_ShapeV2(hnd: TFACE_Handle; index: Integer): TArrayVec2;
    function Face_Shape_rect(hnd: TFACE_Handle; index: Integer): TRectV2;
    procedure Face_Close(var hnd: TFACE_Handle);

    // MDNN-ResNet(ResNet metric DNN) training
    class function Init_Metric_ResNet_Parameter(train_sync_file, train_output: TPascalString): PMetric_ResNet_Train_Parameter;
    class procedure Free_Metric_ResNet_Parameter(param: PMetric_ResNet_Train_Parameter);
    function Metric_ResNet_Train(imgList: TMemoryRaster2DArray; param: PMetric_ResNet_Train_Parameter): Boolean; overload;
    function Metric_ResNet_Train(imgList: TAI_ImageList; param: PMetric_ResNet_Train_Parameter): Boolean; overload;
    function Metric_ResNet_Train_Stream(imgList: TAI_ImageList; param: PMetric_ResNet_Train_Parameter): TMemoryStream64; overload;
    function Metric_ResNet_Train(imgMat: TAI_ImageMatrix; param: PMetric_ResNet_Train_Parameter): Boolean; overload;
    function Metric_ResNet_Train_Stream(imgMat: TAI_ImageMatrix; param: PMetric_ResNet_Train_Parameter): TMemoryStream64; overload;
    // MDNN-ResNet(ResNet metric DNN) api
    function Metric_ResNet_Open(train_file: TPascalString): TMDNN_Handle;
    function Metric_ResNet_Open_Stream(stream: TMemoryStream64): TMDNN_Handle; overload;
    function Metric_ResNet_Open_Stream(train_file: TPascalString): TMDNN_Handle; overload;
    function Metric_ResNet_Close(var hnd: TMDNN_Handle): Boolean;
    function Metric_ResNet_Process(hnd: TMDNN_Handle; RasterArray: TMemoryRasterArray; output: PDouble): Integer; overload;
    function Metric_ResNet_Process(hnd: TMDNN_Handle; Raster: TMemoryRaster): TLVec; overload;
    procedure Metric_ResNet_SaveDetectorDefineToLearnEngine(mdnn_hnd: TMDNN_Handle; imgList: TAI_ImageList; lr: TLearn); overload;
    procedure Metric_ResNet_SaveDetectorDefineToLearnEngine(mdnn_hnd: TMDNN_Handle; imgMat: TAI_ImageMatrix; lr: TLearn); overload;
    function Metric_ResNet_DebugInfo(hnd: TMDNN_Handle): TPascalString;

    // MMOD-DNN(DNN+SVM:max-margin object detector) training
    class function Init_MMOD_DNN_TrainParam(train_cfg, train_sync_file, train_output: TPascalString): PMMOD_Train_Parameter;
    class procedure Free_MMOD_DNN_TrainParam(param: PMMOD_Train_Parameter);
    function MMOD_DNN_PrepareTrain(imgList: TAI_ImageList; train_sync_file: TPascalString): PMMOD_Train_Parameter; overload;
    function MMOD_DNN_PrepareTrain(imgMat: TAI_ImageMatrix; train_sync_file: TPascalString): PMMOD_Train_Parameter; overload;
    function MMOD_DNN_Train(param: PMMOD_Train_Parameter): Integer;
    function MMOD_DNN_Train_Stream(param: PMMOD_Train_Parameter): TMemoryStream64;
    procedure MMOD_DNN_FreeTrain(param: PMMOD_Train_Parameter);
    // MMOD-DNN(DNN+SVM:max-margin object detector) api
    function MMOD_DNN_Open(train_file: TPascalString): TMMOD_Handle;
    function MMOD_DNN_Open_Stream(stream: TMemoryStream64): TMMOD_Handle; overload;
    function MMOD_DNN_Open_Stream(train_file: TPascalString): TMMOD_Handle; overload;
    function MMOD_DNN_Close(var hnd: TMMOD_Handle): Boolean;
    function MMOD_DNN_Process(hnd: TMMOD_Handle; Raster: TMemoryRaster): TMMOD_Desc; overload;
    function MMOD_DNN_Process_Matrix(hnd: TMMOD_Handle; matrix_img: TMatrix_Image_Handle): TMMOD_Desc; overload;
    function MMOD_DNN_DebugInfo(hnd: TMMOD_Handle): TPascalString;

    // ResNet-Image-Classifier training
    class function Init_RNIC_Train_Parameter(train_sync_file, train_output: TPascalString): PRNIC_Train_Parameter;
    class procedure Free_RNIC_Train_Parameter(param: PRNIC_Train_Parameter);
    function RNIC_Train(imgList: TMemoryRaster2DArray; param: PRNIC_Train_Parameter; Train_OutputIndex: TMemoryRasterList): Boolean; overload;
    function RNIC_Train(imgList: TAI_ImageList; param: PRNIC_Train_Parameter; Train_OutputIndex: TPascalStringList): Boolean; overload;
    function RNIC_Train(imgList: TAI_ImageList; param: PRNIC_Train_Parameter; train_index_output: TPascalString): Boolean; overload;
    function RNIC_Train_Stream(imgList: TAI_ImageList; param: PRNIC_Train_Parameter; Train_OutputIndex: TPascalStringList): TMemoryStream64; overload;
    function RNIC_Train(imgMat: TAI_ImageMatrix; param: PRNIC_Train_Parameter; Train_OutputIndex: TPascalStringList): Boolean; overload;
    function RNIC_Train(imgMat: TAI_ImageMatrix; param: PRNIC_Train_Parameter; train_index_output: TPascalString): Boolean; overload;
    function RNIC_Train_Stream(imgMat: TAI_ImageMatrix; param: PRNIC_Train_Parameter; Train_OutputIndex: TPascalStringList): TMemoryStream64; overload;
    // ResNet-Image-Classifier api
    function RNIC_Open(train_file: TPascalString): TRNIC_Handle;
    function RNIC_Open_Stream(stream: TMemoryStream64): TRNIC_Handle; overload;
    function RNIC_Open_Stream(train_file: TPascalString): TRNIC_Handle; overload;
    function RNIC_Close(var hnd: TRNIC_Handle): Boolean;
    function RNIC_Process(hnd: TRNIC_Handle; Raster: TMemoryRaster): TLVec;
    function RNIC_DebugInfo(hnd: TRNIC_Handle): TPascalString;

    // video tracker
    function Tracker_Open(Raster: TMemoryRaster; track_rect: TRect): TTracker_Handle;
    function Tracker_OpenV2(Raster: TMemoryRaster; track_rect: TRectV2): TTracker_Handle;
    function Tracker_Update(hnd: TTracker_Handle; Raster: TMemoryRaster; var track_rect: TRect): Double;
    function Tracker_UpdateV2(hnd: TTracker_Handle; Raster: TMemoryRaster; var track_rect: TRectV2): Double;
    function Tracker_Close(var hnd: TTracker_Handle): Boolean;

    // engine activted
    function Activted: Boolean;
  end;

{$IFDEF FPC}

  TAI_Parallel_Decl = specialize TGenericsList<TAI>;
{$ELSE FPC}
  TAI_Parallel_Decl = TGenericsObjectList<TAI>;
{$ENDIF FPC}

  TAI_Parallel = class(TAI_Parallel_Decl)
  private
    Critical: TSoftCritical;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Delete(index: Integer);

    procedure Prepare_Parallel(eng: SystemString; poolSiz: Integer); overload;
    procedure Prepare_Parallel(lib_p: Pointer; poolSiz: Integer); overload;
    procedure Prepare_Parallel; overload;

    procedure Prepare_Face;
    procedure Prepare_OD(stream: TMemoryStream64);
    procedure Prepare_OD_Marshal(stream: TMemoryStream64);
    procedure Prepare_SP(stream: TMemoryStream64);
    procedure Prepare_MDNN(stream: TMemoryStream64);
    procedure Prepare_MMOD(stream: TMemoryStream64);
    procedure Prepare_RNIC(stream: TMemoryStream64);
    function GetAndLockAI: TAI;
    procedure UnLockAI(AI: TAI);
  end;

const
  // core parameter
  C_Metric_ResNet_Image_Size: Integer = 150;
  C_Metric_ResNet_Dim: Integer = 256;
  C_ResNet_Image_Classifier_Dim: Integer = 1000;

  // ext define
  C_ImageMatrix_Ext: SystemString = '.imgMat';
  C_ImageList_Ext: SystemString = '.imgDataset';
  C_OD_Ext: SystemString = '.svm_od';
  C_OD_Marshal_Ext: SystemString = '.svm_od_marshal';
  C_SP_Ext: SystemString = '.shape';
  C_Metric_ResNet_Ext: SystemString = '.metric';
  C_MMOD_Ext: SystemString = '.svm_dnn_od';
  C_RNIC_Ext: SystemString = '.rnic';

procedure Wait_AI_Init;
function Prepare_AI_Engine(eng: SystemString): Pointer; overload;
procedure Prepare_AI_Engine; overload;
procedure Close_AI_Engine;

function Alloc_P_Bytes(const buff: TPascalString): P_Bytes; overload;
function Alloc_P_Bytes(const buff: TBytes): P_Bytes; overload;
function Alloc_P_Bytes(const buff: Pointer; siz: Integer): P_Bytes; overload;
procedure Free_P_Bytes(const buff: P_Bytes);
function Get_P_Bytes_String(const buff: P_Bytes): TPascalString;

function Rect(const v: TAI_Rect): TRect; overload;
function AIRect(const v: TRect): TAI_Rect; overload;
function AIRect(const v: TRectV2): TAI_Rect; overload;
function AIRect(const v: TAI_MMOD_Rect): TAI_Rect; overload;
function RectV2(const v: TAI_Rect): TRectV2; overload;
function RectV2(const v: TAI_MMOD_Rect): TRectV2; overload;
function point(const v: TAI_Point): TPoint; overload;
function Vec2(const v: TAI_Point): TVec2; overload;
function InRect(v: TAI_Point; R: TAI_Rect): Boolean; overload;
function InRect(v: TSP_Desc; R: TAI_Rect): Boolean; overload;
function InRect(v: TSP_Desc; R: TRectV2): Boolean; overload;
procedure SPToVec(v: TSP_Desc; l: TVec2List); overload;
function GetSPBound(desc: TSP_Desc; endge_threshold: TGeoFloat): TRectV2;
procedure Build_XML_Dataset(xslFile, name, comment, body: SystemString; build_output: TMemoryStream64);
procedure Build_XML_Style(build_output: TMemoryStream64);
procedure DrawSPLine(sp_desc: TSP_Desc; bp, ep: Integer; closeLine: Boolean; color: TDEColor; d: TDrawEngine); overload;
procedure DrawSPLine(sp_desc: TVec2List; bp, ep: Integer; closeLine: Boolean; color: TDEColor; d: TDrawEngine); overload;
procedure DrawSPLine(sp_desc: TArrayVec2; bp, ep: Integer; closeLine: Boolean; color: TDEColor; d: TDrawEngine); overload;
procedure DrawFaceSP(sp_desc: TSP_Desc; color: TDEColor; d: TDrawEngine); overload;
procedure DrawFaceSP(sp_desc: TVec2List; color: TDEColor; d: TDrawEngine); overload;
procedure DrawFaceSP(sp_desc: TArrayVec2; color: TDEColor; d: TDrawEngine); overload;

implementation

uses
{$IFDEF parallel}
{$IFDEF FPC}
  mtprocs,
{$ELSE FPC}
  Threading,
{$ENDIF FPC}
{$ENDIF parallel}
  SyncObjs, DoStatusIO, Math;

{$IFDEF Z_AI_Dataset_Build_In}
{$RESOURCE zAI_BuildIn.RES}
{$ENDIF Z_AI_Dataset_Build_In}


var
  AI_Entry_Cache: THashList;
  AI_Status_Critical: TCritical;
  AI_Status_Buffer: TMemoryStream64;
  AI_BuildIn: TObjectDataManager;
  build_in_face_shape_memory: Pointer;
  build_in_face_shape_memory_siz: Int64;

procedure AI_OnOneStep(Sender: PAI_Entry; one_step_calls: UInt64; average_loss, learning_rate: Double); stdcall;
begin
  try
      Sender^.OneStepList.AddStep(one_step_calls, average_loss, learning_rate);
  except
  end;
end;

procedure AI_OnPause(); stdcall;
begin
end;

// i_char = unicode encoded char
procedure AI_StatusIO_Out(Sender: PAI_Entry; i_char: Integer); stdcall;
var
  buff: TBytes;
  al: TAI_Log;
begin
  AI_Status_Critical.Acquire;
  try
    if (i_char in [10, 13]) then
      begin
        if (AI_Status_Buffer.Size > 0) then
          begin
            SetLength(buff, AI_Status_Buffer.Size);
            CopyPtr(AI_Status_Buffer.memory, @buff[0], AI_Status_Buffer.Size);
            AI_Status_Buffer.Clear;

            al.LogTime := umlNow();
            al.LogText := umlStringOf(buff);
            Sender^.Log.Add(al);

            DoStatus(al.LogText, i_char);

            SetLength(buff, 0);
          end
        else if i_char = 10 then
            DoStatus('');
      end
    else
      begin
        AI_Status_Buffer.WriteUInt8(i_char);
      end;
  except
  end;
  AI_Status_Critical.Release;
end;

function AI_GetTimeTick64(): UInt64; stdcall;
begin
  Result := GetTimeTick();
end;

function AI_BuildString(p: Pointer; Size: Integer): Pointer; stdcall;
var
  b: TBytes;
  pp: PPascalString;
begin
  new(pp);
  pp^ := '';
  Result := pp;
  if Size > 0 then
    begin
      SetLength(b, Size);
      CopyPtr(p, @b[0], Size);
      pp^.Bytes := b;
      SetLength(b, 0);
    end;
end;

procedure AI_FreeString(p: Pointer); stdcall;
begin
  Dispose(PPascalString(p));
end;

function Load_ZAI(libFile: SystemString): PAI_Entry;
type
  TProc_Init_ai = procedure(var AI: TAI_Entry); stdcall;
var
  proc_init_ai_: TProc_Init_ai;
  AI_Ptr: PAI_Entry;
begin
  Result := nil;

  LockObject(AI_Entry_Cache);
  try

    if AI_Entry_Cache.Exists(libFile) then
      begin
        AI_Ptr := PAI_Entry(AI_Entry_Cache[libFile]);
        Result := AI_Ptr;
      end
    else
      begin
        try
            proc_init_ai_ := TProc_Init_ai(GetExtProc(libFile, 'init_api_entry'));
        except
            FreeExtLib(libFile);
        end;
        if Assigned(proc_init_ai_) then
          begin
            new(AI_Ptr);
            FillPtrByte(AI_Ptr, SizeOf(TAI_Entry), 0);
            AI_Ptr^.API_OnOneStep := {$IFDEF FPC}@{$ENDIF FPC}AI_OnOneStep;
            AI_Ptr^.API_OnPause := {$IFDEF FPC}@{$ENDIF FPC}AI_OnPause;
            AI_Ptr^.API_Status_Out := {$IFDEF FPC}@{$ENDIF FPC}AI_StatusIO_Out;
            AI_Ptr^.API_GetTimeTick64 := {$IFDEF FPC}@{$ENDIF FPC}AI_GetTimeTick64;
            AI_Ptr^.API_BuildString := {$IFDEF FPC}@{$ENDIF FPC}AI_BuildString;
            AI_Ptr^.API_FreeString := {$IFDEF FPC}@{$ENDIF FPC}AI_FreeString;
            AI_Ptr^.LibraryFile := libFile;
            AI_Ptr^.LoadLibraryTime := umlNow();
            AI_Ptr^.OneStepList := TOneStepList.Create;
            AI_Ptr^.Log := TAI_LogList.Create;
            try
              proc_init_ai_(AI_Ptr^);
              AI_Ptr^.Key := AIKey(AI_Ptr^.Key);
              if AI_Ptr^.CheckKey() > 0 then
                begin
                  AI_Entry_Cache.Add(libFile, AI_Ptr, False);
                  Result := AI_Ptr;
                  DoStatus('prepare AI engine: %s', [libFile]);
                end
              else
                begin
                  Dispose(AI_Ptr);
                  FreeExtLib(libFile);
                  DoStatus('illegal AI engine: %s', [libFile]);
                end;
            except
            end;
          end;
      end;
  finally
      UnLockObject(AI_Entry_Cache);
  end;
end;

type
  TBuildIn_Thread = class(TCoreClassThread)
  protected
    procedure Execute; override;
  end;

procedure TBuildIn_Thread.Execute;
var
  rs: TCoreClassStream;
  m64: TMemoryStream64;
  dbEng: TObjectDataManager;
  itmHnd: TItemHandle;
  p: Pointer;
begin
{$IFDEF Z_AI_Dataset_Build_In}
  rs := TCoreClassResourceStream.Create(HInstance, 'zAI_BuildIn', RT_RCDATA);
{$ELSE Z_AI_Dataset_Build_In}
  if not umlFileExists(umlCombineFileName(AI_Configure_Path, 'zAI_BuildIn.OXC')) then
      RaiseInfo('not found AI dataset %s', [umlCombineFileName(AI_Configure_Path, 'zAI_BuildIn.OXC').Text]);
  rs := TCoreClassFileStream.Create(umlCombineFileName(AI_Configure_Path, 'zAI_BuildIn.OXC'), fmOpenRead or fmShareDenyWrite);
{$ENDIF Z_AI_Dataset_Build_In}
  rs.Position := 0;
  m64 := TMemoryStream64.Create;
  DecompressStream(rs, m64);
  disposeObject(rs);

  m64.Position := 0;
  dbEng := TObjectDataManagerOfCache.CreateAsStream(m64, '', DBMarshal.ID, True, False, True);

  if dbEng.ItemOpen('/', 'build_in_face_shape.dat', itmHnd) then
    begin
      build_in_face_shape_memory_siz := itmHnd.Item.Size;
      p := GetMemory(build_in_face_shape_memory_siz);
      dbEng.ItemRead(itmHnd, build_in_face_shape_memory_siz, p^);
      dbEng.ItemClose(itmHnd);
    end;

  AI_BuildIn := dbEng;
  build_in_face_shape_memory := p;
end;

procedure Init_AI_BuildIn;
var
  th: TBuildIn_Thread;
begin
  AI_Status_Critical := TCritical.Create;
  AI_Entry_Cache := THashList.Create;
  AI_Entry_Cache.AutoFreeData := False;
  AI_Entry_Cache.AccessOptimization := False;
  AI_Status_Buffer := TMemoryStream64.CustomCreate(8192);

  AI_BuildIn := nil;
  build_in_face_shape_memory := nil;
  build_in_face_shape_memory_siz := 0;

  th := TBuildIn_Thread.Create(True);
  th.FreeOnTerminate := True;
  th.Suspended := False;
end;

procedure Wait_AI_Init;
begin
  while (AI_BuildIn = nil) or (build_in_face_shape_memory = nil) or (build_in_face_shape_memory_siz = 0) do
      CheckThreadSynchronize(10);
end;

procedure Free_AI_BuildIn;
begin
  Close_AI_Engine;
  disposeObject(AI_Entry_Cache);
  disposeObject(AI_Status_Buffer);
  disposeObject(AI_BuildIn);
  disposeObject(AI_Status_Critical);
  FreeMemory(build_in_face_shape_memory);
end;

function Prepare_AI_Engine(eng: SystemString): Pointer;
begin
  Result := Load_ZAI(eng);
end;

procedure Prepare_AI_Engine;
begin
  Prepare_AI_Engine(AI_Engine_Library);
end;

procedure Close_AI_Engine;
  procedure Free_ZAI(AI_Ptr: PAI_Entry);
  begin
    try
      AI_Ptr^.CloseAI();
      disposeObject(AI_Ptr^.OneStepList);
      disposeObject(AI_Ptr^.Log);
      Dispose(AI_Ptr);
    except
    end;
  end;

var
  i: Integer;
  p: PHashListData;
begin
  Wait_AI_Init;

  if AI_Entry_Cache.Count > 0 then
    begin
      i := 0;
      p := AI_Entry_Cache.FirstPtr;
      while i < AI_Entry_Cache.Count do
        begin
          Free_ZAI(PAI_Entry(p^.data));
          p^.data := nil;
          FreeExtLib(p^.OriginName);
          inc(i);
          p := p^.Next;
        end;
    end;
  AI_Entry_Cache.Clear;
end;

function Alloc_P_Bytes(const buff: TPascalString): P_Bytes;
begin
  Result := Alloc_P_Bytes(buff.Bytes);
end;

function Alloc_P_Bytes(const buff: TBytes): P_Bytes;
begin
  new(Result);
  Result^.Size := length(buff);
  if Result^.Size > 0 then
    begin
      Result^.Bytes := GetMemory(Result^.Size + 1);
      CopyPtr(@buff[0], Result^.Bytes, Result^.Size);
    end
  else
      Result^.Bytes := nil;
end;

function Alloc_P_Bytes(const buff: Pointer; siz: Integer): P_Bytes;
begin
  new(Result);
  Result^.Size := siz;
  if Result^.Size > 0 then
    begin
      Result^.Bytes := GetMemory(Result^.Size + 1);
      CopyPtr(buff, Result^.Bytes, Result^.Size);
    end
  else
      Result^.Bytes := nil;
end;

procedure Free_P_Bytes(const buff: P_Bytes);
begin
  if (buff = nil) then
      exit;
  if (buff^.Size > 0) and (buff^.Bytes <> nil) then
      FreeMemory(buff^.Bytes);
  Dispose(buff);
end;

function Get_P_Bytes_String(const buff: P_Bytes): TPascalString;
var
  tmp: TBytes;
begin
  SetLength(tmp, buff^.Size);
  if buff^.Size > 0 then
      CopyPtr(buff^.Bytes, @tmp[0], buff^.Size);
  Result.Bytes := tmp;
  SetLength(tmp, 0);
end;

function Rect(const v: TAI_Rect): TRect;
begin
  Result.Left := v.Left;
  Result.Top := v.Top;
  Result.Right := v.Right;
  Result.Bottom := v.Bottom;
end;

function AIRect(const v: TRect): TAI_Rect;
begin
  Result.Left := v.Left;
  Result.Top := v.Top;
  Result.Right := v.Right;
  Result.Bottom := v.Bottom;
end;

function AIRect(const v: TRectV2): TAI_Rect;
begin
  Result.Left := Round(v[0, 0]);
  Result.Top := Round(v[0, 1]);
  Result.Right := Round(v[1, 0]);
  Result.Bottom := Round(v[1, 1]);
end;

function AIRect(const v: TAI_MMOD_Rect): TAI_Rect;
begin
  Result.Left := v.Left;
  Result.Top := v.Top;
  Result.Right := v.Right;
  Result.Bottom := v.Bottom;
end;

function RectV2(const v: TAI_Rect): TRectV2;
begin
  Result[0, 0] := v.Left;
  Result[0, 1] := v.Top;
  Result[1, 0] := v.Right;
  Result[1, 1] := v.Bottom;
end;

function RectV2(const v: TAI_MMOD_Rect): TRectV2;
begin
  Result[0, 0] := v.Left;
  Result[0, 1] := v.Top;
  Result[1, 0] := v.Right;
  Result[1, 1] := v.Bottom;
end;

function point(const v: TAI_Point): TPoint;
begin
  Result.x := v.x;
  Result.y := v.y;
end;

function Vec2(const v: TAI_Point): TVec2;
begin
  Result[0] := v.x;
  Result[1] := v.y;
end;

function InRect(v: TAI_Point; R: TAI_Rect): Boolean;
begin
  Result := PointInRect(Vec2(v), RectV2(R));
end;

function InRect(v: TSP_Desc; R: TAI_Rect): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to length(v) - 1 do
    if not InRect(v[i], R) then
        exit;
  Result := True;
end;

function InRect(v: TSP_Desc; R: TRectV2): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to length(v) - 1 do
    if not PointInRect(Vec2(v[i]), R) then
        exit;
  Result := True;
end;

procedure SPToVec(v: TSP_Desc; l: TVec2List);
var
  i: Integer;
begin
  for i := 0 to length(v) - 1 do
      l.Add(Vec2(v[i]));
end;

function GetSPBound(desc: TSP_Desc; endge_threshold: TGeoFloat): TRectV2;
var
  vbuff: TArrayVec2;
  i: Integer;
  siz: TVec2;
begin
  if length(desc) = 0 then
    begin
      Result := NullRect;
      exit;
    end;
  SetLength(vbuff, length(desc));
  for i := 0 to length(desc) - 1 do
      vbuff[i] := Vec2(desc[i]);

  Result := FixRect(BoundRect(vbuff));
  SetLength(vbuff, 0);

  if IsEqual(endge_threshold, 0) then
      exit;

  siz := Vec2Mul(RectSize(Result), endge_threshold);
  Result[0] := Vec2Sub(Result[0], siz);
  Result[1] := Vec2Add(Result[1], siz);
end;

procedure Build_XML_Dataset(xslFile, name, comment, body: SystemString; build_output: TMemoryStream64);
const
  XML_Dataset =
    '<?xml version='#39'1.0'#39' encoding='#39'UTF-8'#39'?>'#13#10 +
    '<?xml-stylesheet type='#39'text/xsl'#39' href='#39'%xsl%'#39'?>'#13#10 +
    '<dataset>'#13#10 +
    '<name>%name%</name>'#13#10 +
    '<comment>%comment%</comment>'#13#10 +
    '<images>'#13#10 +
    '%body%'#13#10 +
    '</images>'#13#10 +
    '</dataset>'#13#10;

var
  vt: THashStringList;
  s_out: SystemString;
  l: TPascalStringList;
begin
  vt := THashStringList.Create;
  vt['xsl'] := xslFile;
  vt['name'] := name;
  vt['comment'] := comment;
  vt['body'] := body;
  vt.ProcessMacro(XML_Dataset, '%', '%', s_out);
  disposeObject(vt);
  l := TPascalStringList.Create;
  l.Text := s_out;
  l.SaveToStream(build_output);
  disposeObject(l);
end;

procedure Build_XML_Style(build_output: TMemoryStream64);
const
  XML_Style = '<?xml version="1.0" encoding="UTF-8" ?>'#13#10 +
    '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">'#13#10 +
    '<xsl:output method='#39'html'#39' version='#39'1.0'#39' encoding='#39'UTF-8'#39' indent='#39'yes'#39' />'#13#10 +
    '<xsl:variable name="max_images_displayed">30</xsl:variable>'#13#10 +
    '   <xsl:template match="/dataset">'#13#10 +
    '      <html>'#13#10 +
    '         <head>'#13#10 +
    '            '#13#10 +
    '            <style type="text/css">'#13#10 +
    '               div#box{'#13#10 +
    '                  position: absolute; '#13#10 +
    '                  border-style:solid; '#13#10 +
    '                  border-width:3px; '#13#10 +
    '                  border-color:red;'#13#10 +
    '               }'#13#10 +
    '               div#circle{'#13#10 +
    '                  position: absolute; '#13#10 +
    '                  border-style:solid; '#13#10 +
    '                  border-width:1px; '#13#10 +
    '                  border-color:red;'#13#10 +
    '                  border-radius:7px;'#13#10 +
    '                  width:2px; '#13#10 +
    '                  height:2px;'#13#10 +
    '               }'#13#10 +
    '               div#label{'#13#10 +
    '                  position: absolute; '#13#10 +
    '                  color: red;'#13#10 +
    '               }'#13#10 +
    '               div#img{'#13#10 +
    '                  position: relative;'#13#10 +
    '                  margin-bottom:2em;'#13#10 +
    '               }'#13#10 +
    '               pre {'#13#10 +
    '                  color: black;'#13#10 +
    '                  margin: 1em 0.25in;'#13#10 +
    '                  padding: 0.5em;'#13#10 +
    '                  background: rgb(240,240,240);'#13#10 +
    '                  border-top: black dotted 1px;'#13#10 +
    '                  border-left: black dotted 1px;'#13#10 +
    '                  border-right: black solid 2px;'#13#10 +
    '                  border-bottom: black solid 2px;'#13#10 +
    '               }'#13#10 +
    '            </style>'#13#10 +
    '         </head>'#13#10 +
    '         <body>'#13#10 +
    '            ZAI Dataset name: <b><xsl:value-of select='#39'/dataset/name'#39'/></b> <br/>'#13#10 +
    '            ZAI comment: <b><xsl:value-of select='#39'/dataset/comment'#39'/></b> <br/> '#13#10 +
    '            include <xsl:value-of select="count(images/image)"/> of picture and <xsl:value-of select="count(images/image/box)"/> detector <br/>'#13#10 +
    '            <xsl:if test="count(images/image) &gt; $max_images_displayed">'#13#10 +
    '               <h2>max display <xsl:value-of select="$max_images_displayed"/> of picture.</h2>'#13#10 +
    '               <hr/>'#13#10 +
    '            </xsl:if>'#13#10 +
    '            <xsl:for-each select="images/image">'#13#10 +
    '               <xsl:if test="position() &lt;= $max_images_displayed">'#13#10 +
    '                  detector: <xsl:value-of select="count(box)"/>'#13#10 +
    '                  <div id="img">'#13#10 +
    '                     <img src="{@file}"/>'#13#10 +
    '                     <xsl:for-each select="box">'#13#10 +
    '                        <div id="box" style="top: {@top}px; left: {@left}px; width: {@width}px; height: {@height}px;"></div>'#13#10 +
    '                        <xsl:if test="label">'#13#10 +
    '                           <div id="label" style="top: {@top+@height}px; left: {@left+@width}px;">'#13#10 +
    '                              <xsl:value-of select="label"/>'#13#10 +
    '                           </div>'#13#10 +
    '                        </xsl:if>'#13#10 +
    '                        <xsl:for-each select="part">'#13#10 +
    '                           <div id="circle" style="top: {(@y)}px; left: {(@x)}px; "></div>'#13#10 +
    '                        </xsl:for-each>'#13#10 +
    '                     </xsl:for-each>'#13#10 +
    '                  </div>'#13#10 +
    '               </xsl:if>'#13#10 +
    '            </xsl:for-each>'#13#10 +
    '         </body>'#13#10 +
    '      </html>'#13#10 +
    '   </xsl:template>'#13#10 +
    '</xsl:stylesheet>'#13#10;

var
  l: TPascalStringList;
begin
  l := TPascalStringList.Create;
  l.Text := XML_Style;
  l.SaveToStream(build_output);
  disposeObject(l);
end;

procedure DrawSPLine(sp_desc: TSP_Desc; bp, ep: Integer; closeLine: Boolean; color: TDEColor; d: TDrawEngine);
var
  i: Integer;
  vl: TVec2List;
begin
  vl := TVec2List.Create;
  for i := bp to ep do
      vl.Add(Vec2(sp_desc[i]));

  d.DrawPL(20, vl, closeLine, color, 2);
  disposeObject(vl);
end;

procedure DrawSPLine(sp_desc: TVec2List; bp, ep: Integer; closeLine: Boolean; color: TDEColor; d: TDrawEngine);
var
  i: Integer;
  vl: TVec2List;
begin
  vl := TVec2List.Create;
  for i := bp to ep do
      vl.Add(sp_desc[i]^);

  d.DrawPL(20, vl, closeLine, color, 2);
  disposeObject(vl);
end;

procedure DrawSPLine(sp_desc: TArrayVec2; bp, ep: Integer; closeLine: Boolean; color: TDEColor; d: TDrawEngine);
var
  i: Integer;
  vl: TVec2List;
begin
  vl := TVec2List.Create;
  for i := bp to ep do
      vl.Add(sp_desc[i]);

  d.DrawPL(20, vl, closeLine, color, 2);
  disposeObject(vl);
end;

procedure DrawFaceSP(sp_desc: TSP_Desc; color: TDEColor; d: TDrawEngine);
begin
  if length(sp_desc) <> 68 then
      exit;
  DrawSPLine(sp_desc, 0, 16, False, color, d);
  DrawSPLine(sp_desc, 17, 21, False, color, d);
  DrawSPLine(sp_desc, 22, 26, False, color, d);
  DrawSPLine(sp_desc, 27, 30, False, color, d);
  DrawSPLine(sp_desc, 31, 35, False, color, d);
  d.DrawLine(Vec2(sp_desc[31]), Vec2(sp_desc[27]), color, 1);
  d.DrawLine(Vec2(sp_desc[35]), Vec2(sp_desc[27]), color, 1);
  d.DrawLine(Vec2(sp_desc[31]), Vec2(sp_desc[30]), color, 1);
  d.DrawLine(Vec2(sp_desc[35]), Vec2(sp_desc[30]), color, 1);
  DrawSPLine(sp_desc, 36, 41, True, color, d);
  DrawSPLine(sp_desc, 42, 47, True, color, d);
  DrawSPLine(sp_desc, 48, 59, True, color, d);
  DrawSPLine(sp_desc, 60, 67, True, color, d);
end;

procedure DrawFaceSP(sp_desc: TVec2List; color: TDEColor; d: TDrawEngine);
begin
  if sp_desc.Count <> 68 then
      exit;
  DrawSPLine(sp_desc, 0, 16, False, color, d);
  DrawSPLine(sp_desc, 17, 21, False, color, d);
  DrawSPLine(sp_desc, 22, 26, False, color, d);
  DrawSPLine(sp_desc, 27, 30, False, color, d);
  DrawSPLine(sp_desc, 31, 35, False, color, d);
  d.DrawLine(sp_desc[31]^, sp_desc[27]^, color, 1);
  d.DrawLine(sp_desc[35]^, sp_desc[27]^, color, 1);
  d.DrawLine(sp_desc[31]^, sp_desc[30]^, color, 1);
  d.DrawLine(sp_desc[35]^, sp_desc[30]^, color, 1);
  DrawSPLine(sp_desc, 36, 41, True, color, d);
  DrawSPLine(sp_desc, 42, 47, True, color, d);
  DrawSPLine(sp_desc, 48, 59, True, color, d);
  DrawSPLine(sp_desc, 60, 67, True, color, d);
end;

procedure DrawFaceSP(sp_desc: TArrayVec2; color: TDEColor; d: TDrawEngine);
begin
  if length(sp_desc) <> 68 then
      exit;
  DrawSPLine(sp_desc, 0, 16, False, color, d);
  DrawSPLine(sp_desc, 17, 21, False, color, d);
  DrawSPLine(sp_desc, 22, 26, False, color, d);
  DrawSPLine(sp_desc, 27, 30, False, color, d);
  DrawSPLine(sp_desc, 31, 35, False, color, d);
  d.DrawLine(sp_desc[31], sp_desc[27], color, 1);
  d.DrawLine(sp_desc[35], sp_desc[27], color, 1);
  d.DrawLine(sp_desc[31], sp_desc[30], color, 1);
  d.DrawLine(sp_desc[35], sp_desc[30], color, 1);
  DrawSPLine(sp_desc, 36, 41, True, color, d);
  DrawSPLine(sp_desc, 42, 47, True, color, d);
  DrawSPLine(sp_desc, 48, 59, True, color, d);
  DrawSPLine(sp_desc, 60, 67, True, color, d);
end;

constructor TAI_DetectorDefine.Create(AOwner: TAI_Image);
begin
  inherited Create;
  Owner := AOwner;
  R.Left := 0;
  R.Top := 0;
  R.Right := 0;
  R.Bottom := 0;
  Token := '';
  Part := TVec2List.Create;
  PrepareRaster := TMemoryRaster.Create;
end;

destructor TAI_DetectorDefine.Destroy;
begin
  disposeObject(PrepareRaster);
  disposeObject(Part);
  inherited Destroy;
end;

procedure TAI_DetectorDefine.SaveToStream(stream: TMemoryStream64);
var
  de: TDataFrameEngine;
  m64: TMemoryStream64;
begin
  de := TDataFrameEngine.Create;
  de.WriteRect(R);
  de.WriteString(Token);

  m64 := TMemoryStream64.Create;
  Part.SaveToStream(m64);
  de.WriteStream(m64);
  disposeObject(m64);

  m64 := TMemoryStream64.CustomCreate(8192);
  if not PrepareRaster.Empty then
      PrepareRaster.SaveToBmp24Stream(m64);
  de.WriteStream(m64);
  disposeObject(m64);

  de.EncodeTo(stream, True);

  disposeObject(de);
end;

procedure TAI_DetectorDefine.LoadFromStream(stream: TMemoryStream64);
var
  de: TDataFrameEngine;
  m64: TMemoryStream64;
begin
  de := TDataFrameEngine.Create;
  de.DecodeFrom(stream);
  R := de.Reader.ReadRect;
  Token := de.Reader.ReadString;

  m64 := TMemoryStream64.CustomCreate(8192);
  de.Reader.ReadStream(m64);
  m64.Position := 0;
  Part.LoadFromStream(m64);
  disposeObject(m64);

  m64 := TMemoryStream64.CustomCreate(8192);
  de.Reader.ReadStream(m64);
  if m64.Size > 0 then
    begin
      m64.Position := 0;
      PrepareRaster.LoadFromStream(m64);
    end;
  disposeObject(m64);

  disposeObject(de);
end;

constructor TAI_Image.Create(AOwner: TAI_ImageList);
begin
  inherited Create;
  Owner := AOwner;
  DetectorDefineList := TDetectorDefineList.Create;
  Raster := TMemoryRaster.Create;
end;

destructor TAI_Image.Destroy;
begin
  Clear;
  disposeObject(DetectorDefineList);
  disposeObject(Raster);
  inherited Destroy;
end;

procedure TAI_Image.Clear;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
      disposeObject(DetectorDefineList[i]);
  DetectorDefineList.Clear;
end;

procedure TAI_Image.ClearPrepareRaster;
var
  i: Integer;
begin
  for i := 0 to DetectorDefineList.Count - 1 do
      DetectorDefineList[i].PrepareRaster.Reset;
end;

procedure TAI_Image.DrawTo(output: TMemoryRaster);
var
  d: TDrawEngine;
  i, j: Integer;
  DetDef: TAI_DetectorDefine;
  pt_p: PVec2;
begin
  d := TDrawEngine.Create;
  d.Options := [];
  output.Assign(Raster);
  d.Rasterization.memory.SetWorkMemory(output);
  d.SetSize(output);

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      d.DrawBox(RectV2(DetDef.R), DEColor(1, 0, 0, 1), 3);

      if DetDef.Part.Count = 68 then
          DrawFaceSP(DetDef.Part, DEColor(1, 0, 0, 1), d)
      else
        for j := 0 to DetDef.Part.Count - 1 do
          begin
            pt_p := DetDef.Part.Points[j];
            d.DrawPoint(pt_p^, DEColor(1, 0, 0, 1), 2, 2);
          end;
    end;

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      if DetDef.Token <> '' then
        begin
          d.BeginCaptureShadow(Vec2(1, 1), 0.9);
          d.DrawText(DetDef.Token, 14, RectV2(DetDef.R), DEColor(1, 1, 1, 1), True);
          d.EndCaptureShadow;
        end;
    end;

  d.Flush;
  disposeObject(d);
end;

function TAI_Image.FoundNoTokenDetectorDefine(output: TMemoryRaster; color: TDEColor): Boolean;
var
  i: Integer;
  DetDef: TAI_DetectorDefine;
  d: TDrawEngine;
begin
  if output <> nil then
    begin
      Result := False;
      output.Assign(Raster);
      d := TDrawEngine.Create;
      d.Rasterization.memory.SetWorkMemory(output);
      d.SetSize(output);
      for i := 0 to DetectorDefineList.Count - 1 do
        begin
          DetDef := DetectorDefineList[i];
          if DetDef.Token = '' then
            begin
              d.FillBox(RectV2(DetDef.R), color);
              d.BeginCaptureShadow(Vec2(1, 1), 0.9);
              d.DrawText('ERROR!!' + #13#10 + 'NULL TOKEN', 12, RectV2(DetDef.R), DEColorInv(color), True);
              d.EndCaptureShadow;
              Result := True;
            end;
        end;
      d.Flush;
      disposeObject(d);
    end
  else
      Result := FoundNoTokenDetectorDefine();
end;

function TAI_Image.FoundNoTokenDetectorDefine: Boolean;
var
  i: Integer;
  DetDef: TAI_DetectorDefine;
begin
  Result := False;
  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      if DetDef.Token = '' then
        begin
          Result := True;
          exit;
        end;
    end;
end;

procedure TAI_Image.SaveToStream(stream: TMemoryStream64; SaveImg: Boolean);
var
  de: TDataFrameEngine;
  m64: TMemoryStream64;
  i: Integer;
  DetDef: TAI_DetectorDefine;
begin
  de := TDataFrameEngine.Create;

  m64 := TMemoryStream64.Create;
  if SaveImg then
      Raster.SaveToBmp24Stream(m64);
  de.WriteStream(m64);
  disposeObject(m64);

  de.WriteInteger(DetectorDefineList.Count);

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      m64 := TMemoryStream64.Create;
      DetDef := DetectorDefineList[i];
      DetDef.SaveToStream(m64);
      de.WriteStream(m64);
      disposeObject(m64);
    end;

  de.EncodeTo(stream, True);

  disposeObject(de);
end;

procedure TAI_Image.LoadFromStream(stream: TMemoryStream64; LoadImg: Boolean);
var
  de: TDataFrameEngine;
  m64: TMemoryStream64;
  i, c: Integer;
  DetDef: TAI_DetectorDefine;
begin
  de := TDataFrameEngine.Create;
  de.DecodeFrom(stream);

  if LoadImg then
    begin
      m64 := TMemoryStream64.Create;
      de.Reader.ReadStream(m64);
      if (m64.Size > 0) then
        begin
          m64.Position := 0;
          Raster.LoadFromStream(m64);
        end;
      disposeObject(m64);
    end
  else
      de.Reader.GoNext;

  c := de.Reader.ReadInteger;

  for i := 0 to c - 1 do
    begin
      m64 := TMemoryStream64.Create;
      de.Reader.ReadStream(m64);
      m64.Position := 0;
      DetDef := TAI_DetectorDefine.Create(Self);
      DetDef.LoadFromStream(m64);
      disposeObject(m64);
      DetectorDefineList.Add(DetDef);
    end;

  disposeObject(de);
end;

procedure TAI_Image.LoadPicture(fileName: SystemString);
begin
  disposeObject(Raster);
  Raster := NewRasterFromFile(fileName);
end;

procedure TAI_Image.Scale(f: TGeoFloat);
var
  i, j: Integer;
  DetDef: TAI_DetectorDefine;
begin
  if IsEqual(f, 1.0) then
      exit;

  Raster.Scale(f);

  for i := 0 to DetectorDefineList.Count - 1 do
    begin
      DetDef := DetectorDefineList[i];
      DetDef.R := MakeRect(RectMul(RectV2(DetDef.R), f));
      DetDef.Part.Mul(f, f);
    end;
end;

function TAI_Image.ExistsToken(Token: TPascalString): Boolean;
begin
  Result := GetTokenCount(Token) > 0;
end;

function TAI_Image.GetTokenCount(Token: TPascalString): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to DetectorDefineList.Count - 1 do
    if umlMultipleMatch(Token, DetectorDefineList[i].Token) then
        inc(Result);
end;

constructor TAI_ImageList.Create;
begin
  inherited Create;
  FileInfo := '';
  UserData := nil;
end;

destructor TAI_ImageList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAI_ImageList.Delete(index: Integer);
begin
  if index >= 0 then
    begin
      disposeObject(Items[index]);
      inherited Delete(index);
    end;
end;

procedure TAI_ImageList.Clear;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      disposeObject(Items[i]);
  inherited Clear;
end;

procedure TAI_ImageList.ClearPrepareRaster;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].ClearPrepareRaster;
end;

procedure TAI_ImageList.DrawTo(output: TMemoryRaster);
var
  rp: TRectPacking;

{$IFDEF parallel}
{$IFDEF FPC}
  procedure FPC_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  var
    mr: TMemoryRaster;
  begin
    mr := NewRaster();
    Items[pass].DrawTo(mr);
    LockObject(rp);
    rp.Add(nil, mr, mr.BoundsRectV2);
    UnLockObject(rp);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure DoFor;
  var
    pass: Integer;
    mr: TMemoryRaster;
  begin
    for pass := 0 to Count - 1 do
      begin
        mr := NewRaster();
        Items[pass].DrawTo(mr);
        rp.Add(nil, mr, mr.BoundsRectV2);
      end;
  end;
{$ENDIF parallel}
  procedure BuildOutput_;
  var
    i: Integer;
    mr: TMemoryRaster;
    d: TDrawEngine;
  begin
    DoStatus('build output.');
    d := TDrawEngine.Create;
    d.Options := [];
    output.SetSize(Round(rp.MaxWidth), Round(rp.MaxHeight));
    FillBlackGrayBackgroundTexture(output, 32);

    d.Rasterization.memory.SetWorkMemory(output);
    d.SetSize(output);

    for i := 0 to rp.Count - 1 do
      begin
        mr := rp[i]^.Data2 as TMemoryRaster;
        d.DrawTexture(mr, mr.BoundsRectV2, rp[i]^.Rect, 1.0);
      end;

    DoStatus('draw imageList.');
    d.Flush;
    disposeObject(d);
  end;

  procedure FreeTemp_;
  var
    i: Integer;
  begin
    for i := 0 to rp.Count - 1 do
        disposeObject(rp[i]^.Data2);
  end;

begin
  if Count = 0 then
      exit;

  if Count = 1 then
    begin
      First.DrawTo(output);
      exit;
    end;

  DoStatus('build rect packing.');
  rp := TRectPacking.Create;
  rp.Margins := 10;

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@FPC_ParallelFor, 0, Count - 1);
{$ELSE FPC}
  TParallel.for(0, Count - 1, procedure(pass: Integer)
    var
      mr: TMemoryRaster;
    begin
      mr := NewRaster();
      Items[pass].DrawTo(mr);
      LockObject(rp);
      rp.Add(nil, mr, mr.BoundsRectV2);
      UnLockObject(rp);
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor;
{$ENDIF parallel}
  rp.Build;
  BuildOutput_;
  FreeTemp_;
  disposeObject(rp);
end;

procedure TAI_ImageList.AddPicture(stream: TCoreClassStream);
var
  img: TAI_Image;
begin
  img := TAI_Image.Create(Self);
  disposeObject(img.Raster);
  img.Raster := NewRasterFromStream(stream);
  Add(img);
end;

procedure TAI_ImageList.AddPicture(fileName: SystemString);
var
  img: TAI_Image;
begin
  img := TAI_Image.Create(Self);
  disposeObject(img.Raster);
  try
      img.Raster := NewRasterFromFile(fileName);
  except
    disposeObject(img);
    exit;
  end;
  Add(img);
end;

procedure TAI_ImageList.AddPicture(R: TMemoryRaster);
var
  img: TAI_Image;
begin
  img := TAI_Image.Create(Self);
  img.Raster.Assign(R);
  Add(img);
end;

procedure TAI_ImageList.LoadFromPictureStream(stream: TCoreClassStream);
begin
  Clear;
  AddPicture(stream);
end;

procedure TAI_ImageList.LoadFromPictureFile(fileName: SystemString);
begin
  Clear;
  AddPicture(fileName);
end;

function TAI_ImageList.PackingRaster: TMemoryRaster;
var
  i: Integer;
  rp: TRectPacking;
  d: TDrawEngine;
  mr: TMemoryRaster;
begin
  Result := NewRaster();
  if Count = 1 then
      Result.Assign(First.Raster)
  else
    begin
      rp := TRectPacking.Create;
      rp.Margins := 10;
      for i := 0 to Count - 1 - 1 do
          rp.Add(nil, Items[i].Raster, Items[i].Raster.BoundsRectV2);
      rp.Build;

      Result.SetSizeF(rp.MaxWidth, rp.MaxHeight, RasterColorF(0, 0, 0, 1));
      d := TDrawEngine.Create;
      d.ViewOptions := [];
      d.Rasterization.memory.SetWorkMemory(Result);
      d.SetSize(Result);

      for i := 0 to rp.Count - 1 do
        begin
          mr := TMemoryRaster(rp[i]^.Data2);
          d.DrawTexture(mr, mr.BoundsRectV2, rp[i]^.Rect, 0, 1.0);
        end;

      d.Flush;
      disposeObject(d);
      disposeObject(rp);
    end;
end;

procedure TAI_ImageList.SaveToPictureStream(stream: TCoreClassStream);
var
  mr: TMemoryRaster;
begin
  mr := PackingRaster();
  mr.SaveToBmp24Stream(stream);
  disposeObject(mr);
end;

procedure TAI_ImageList.SaveToPictureFile(fileName: SystemString);
var
  fs: TCoreClassFileStream;
begin
  fs := TCoreClassFileStream.Create(fileName, fmCreate);
  SaveToPictureStream(fs);
  disposeObject(fs);
end;

procedure TAI_ImageList.SavePrepareRasterToPictureStream(stream: TCoreClassStream);
var
  i, j: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
  rp: TRectPacking;
  mr: TMemoryRaster;
  de: TDrawEngine;
begin
  rp := TRectPacking.Create;
  rp.Margins := 10;
  for i := 0 to Count - 1 - 1 do
    begin
      img := Items[i];
      for j := 0 to img.DetectorDefineList.Count - 1 do
        begin
          DetDef := img.DetectorDefineList[i];
          if not DetDef.PrepareRaster.Empty then
              rp.Add(nil, DetDef.PrepareRaster, DetDef.PrepareRaster.BoundsRectV2);
        end;
    end;
  rp.Build;

  de := TDrawEngine.Create;
  de.SetSize(Round(rp.MaxWidth), Round(rp.MaxHeight));
  de.FillBox(de.ScreenRect, DEColor(0, 0, 0, 0));

  for i := 0 to rp.Count - 1 do
    begin
      mr := rp[i]^.Data2 as TMemoryRaster;
      de.DrawTexture(mr, mr.BoundsRectV2, rp[i]^.Rect, 0, 1.0);
    end;

  de.Flush;
  de.Rasterization.memory.SaveToBmp24Stream(stream);
  disposeObject(de);
  disposeObject(rp);
end;

procedure TAI_ImageList.SavePrepareRasterToPictureFile(fileName: SystemString);
var
  fs: TCoreClassFileStream;
begin
  fs := TCoreClassFileStream.Create(fileName, fmCreate);
  SavePrepareRasterToPictureStream(fs);
  disposeObject(fs);
end;

procedure TAI_ImageList.SaveToStream(stream: TCoreClassStream; SaveImg, Compressed: Boolean);
var
  de: TDataFrameEngine;
  m64: TMemoryStream64;
  i: Integer;
  imgData: TAI_Image;
begin
  de := TDataFrameEngine.Create;

  de.WriteInteger(Count);

  for i := 0 to Count - 1 do
    begin
      m64 := TMemoryStream64.Create;
      imgData := Items[i];
      imgData.SaveToStream(m64, SaveImg);
      de.WriteStream(m64);
      disposeObject(m64);
    end;

  if Compressed then
      de.EncodeAsZLib(stream, False)
  else
      de.EncodeTo(stream, True);

  disposeObject(de);
end;

procedure TAI_ImageList.LoadFromStream(stream: TCoreClassStream; LoadImg: Boolean);
var
  de: TDataFrameEngine;
  i, j, c: Integer;
  m64: TMemoryStream64;
  imgData: TAI_Image;
begin
  Clear;
  de := TDataFrameEngine.Create;
  de.DecodeFrom(stream);

  c := de.Reader.ReadInteger;

  for i := 0 to c - 1 do
    begin
      m64 := TMemoryStream64.Create;
      de.Reader.ReadStream(m64);
      m64.Position := 0;
      imgData := TAI_Image.Create(Self);
      imgData.LoadFromStream(m64, LoadImg);
      disposeObject(m64);
      Add(imgData);
    end;

  disposeObject(de);
end;

procedure TAI_ImageList.LoadFromStream(stream: TCoreClassStream);
begin
  LoadFromStream(stream, True);
end;

procedure TAI_ImageList.SaveToFile(fileName: SystemString);
var
  fs: TReliableFileStream;
begin
  fs := TReliableFileStream.Create(fileName, True, True);
  SaveToStream(fs, True, True);
  disposeObject(fs);
end;

procedure TAI_ImageList.LoadFromFile(fileName: SystemString; LoadImg: Boolean);
var
  fs: TReliableFileStream;
begin
  fs := TReliableFileStream.Create(fileName, False, False);
  LoadFromStream(fs, LoadImg);
  disposeObject(fs);
end;

procedure TAI_ImageList.LoadFromFile(fileName: SystemString);
begin
  LoadFromFile(fileName, True);
end;

procedure TAI_ImageList.Import(imgList: TAI_ImageList);
var
  i: Integer;
  m64: TMemoryStream64;
  imgData: TAI_Image;
begin
  for i := 0 to imgList.Count - 1 do
    begin
      m64 := TMemoryStream64.Create;
      imgList[i].SaveToStream(m64, True);

      imgData := TAI_Image.Create(Self);
      m64.Position := 0;
      imgData.LoadFromStream(m64, True);
      Add(imgData);

      disposeObject(m64);
    end;
end;

procedure TAI_ImageList.CalibrationNullDetectorDefineToken(Token: SystemString);
var
  i, j: Integer;
  imgData: TAI_Image;
  DetDef: TAI_DetectorDefine;
begin
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          DetDef.Token := umlTrimSpace(DetDef.Token);
          if DetDef.Token = '' then
              DetDef.Token := Token;
          DetDef.Token := umlTrimSpace(DetDef.Token);
        end
    end;
end;

procedure TAI_ImageList.CalibrationDetectorDefineTokenPrefix(Prefix: SystemString);
var
  i, j: Integer;
  imgData: TAI_Image;
  DetDef: TAI_DetectorDefine;
begin
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          DetDef.Token := umlTrimSpace(DetDef.Token);
          if DetDef.Token = '' then
              DetDef.Token := Prefix + DetDef.Token;
          DetDef.Token := umlTrimSpace(DetDef.Token);
        end
    end;
end;

procedure TAI_ImageList.CalibrationDetectorDefineTokenSuffix(Suffix: SystemString);
var
  i, j: Integer;
  imgData: TAI_Image;
  DetDef: TAI_DetectorDefine;
begin
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          DetDef.Token := umlTrimSpace(DetDef.Token);
          if DetDef.Token = '' then
              DetDef.Token := DetDef.Token + Suffix;
          DetDef.Token := umlTrimSpace(DetDef.Token);
        end
    end;
end;

procedure TAI_ImageList.Scale(f: TGeoFloat);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Scale(f);
end;

procedure TAI_ImageList.Build_PrepareDataset(outputPath: SystemString);
var
  i, j: Integer;
  imgData: TAI_Image;
  DetDef: TAI_DetectorDefine;
  Raster: TMemoryRaster;
  hList: THashObjectList;
  mrList: TMemoryRasterList;
  pl: TPascalStringList;
  dn, fn: SystemString;
  m64: TMemoryStream64;
begin
  hList := THashObjectList.Create(True);
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if (not DetDef.PrepareRaster.Empty) and (DetDef.Token <> '') then
            begin
              if not hList.Exists(DetDef.Token) then
                  hList.FastAdd(DetDef.Token, TMemoryRasterList.Create);
              TMemoryRasterList(hList[DetDef.Token]).Add(DetDef.PrepareRaster);
            end;
        end;
    end;

  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := TMemoryRasterList(hList[pl[i]]);
      dn := umlCombinePath(outputPath, pl[i]);
      umlCreateDirectory(dn);
      for j := 0 to mrList.Count - 1 do
        begin
          Raster := mrList[j];
          m64 := TMemoryStream64.Create;
          Raster.SaveToBmp24Stream(m64);
          fn := umlCombineFileName(dn, PFormat('%s.bmp', [umlStreamMD5String(m64).Text]));
          m64.SaveToFile(fn);
          disposeObject(m64);
        end;
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

procedure TAI_ImageList.Build_XML(TokenFilter: TPascalString; includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList);
  function num_2(num: Integer): SystemString;
  begin
    if num < 10 then
        Result := PFormat('0%d', [num])
    else
        Result := PFormat('%d', [num]);
  end;

  procedure SaveFileInfo(fn: TPascalString);
  begin
    if BuildFileList <> nil then
      if BuildFileList.ExistsValue(fn) < 0 then
          BuildFileList.Add(fn);
  end;

var
  body: TPascalStringList;
  output_path, n: SystemString;
  i, j, k: Integer;
  imgData: TAI_Image;
  DetDef: TAI_DetectorDefine;
  m5: TMD5;
  m64: TMemoryStream64;
  v_p: PVec2;
  s_body: SystemString;
begin
  body := TPascalStringList.Create;
  output_path := umlGetFilePath(build_output_file);
  umlCreateDirectory(output_path);
  umlSetCurrentPath(output_path);

  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      if (imgData.DetectorDefineList.Count = 0) or (not imgData.ExistsToken(TokenFilter)) then
          continue;

      m64 := TMemoryStream64.Create;
      imgData.Raster.SaveToBmp24Stream(m64);
      m5 := umlStreamMD5(m64);
      n := umlCombineFileName(output_path, Prefix + umlMD5ToStr(m5) + '.bmp');
      if not umlFileExists(n) then
        begin
          m64.SaveToFile(n);
          SaveFileInfo(n);
        end;
      disposeObject(m64);

      body.Add(PFormat(' <image file='#39'%s'#39'>', [umlGetFileName(n).Text]));
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if umlMultipleMatch(TokenFilter, DetDef.Token) then
            begin
              body.Add(PFormat(
                '  <box top='#39'%d'#39' left='#39'%d'#39' width='#39'%d'#39' height='#39'%d'#39'>',
                [DetDef.R.Top, DetDef.R.Left, DetDef.R.width, DetDef.R.height]));

              if includeLabel and (DetDef.Token.Len > 0) then
                  body.Add(PFormat('    <label>%s</label>', [DetDef.Token.Text]));

              if includePart then
                begin
                  for k := 0 to DetDef.Part.Count - 1 do
                    begin
                      v_p := DetDef.Part[k];
                      body.Add(PFormat(
                        '    <part name='#39'%s'#39' x='#39'%d'#39' y='#39'%d'#39'/>',
                        [num_2(k), Round(v_p^[0]), Round(v_p^[1])]));
                    end;
                end;

              body.Add('  </box>');
            end;
        end;
      body.Add(' </image>');
    end;

  s_body := body.Text;
  disposeObject(body);

  m64 := TMemoryStream64.Create;
  Build_XML_Style(m64);
  n := umlCombineFileName(output_path, umlChangeFileExt(umlGetFileName(build_output_file), '.xsl'));
  m64.SaveToFile(n);
  SaveFileInfo(n);
  disposeObject(m64);

  m64 := TMemoryStream64.Create;
  Build_XML_Dataset(umlGetFileName(n), datasetName, comment, s_body, m64);
  m64.SaveToFile(build_output_file);
  SaveFileInfo(build_output_file);
  disposeObject(m64);
end;

procedure TAI_ImageList.Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList);
begin
  Build_XML('', includeLabel, includePart, datasetName, comment, build_output_file, Prefix, BuildFileList);
end;

procedure TAI_ImageList.Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file: SystemString);
begin
  Build_XML('', includeLabel, includePart, datasetName, comment, build_output_file, '', nil);
end;

function TAI_ImageList.DetectorDefineCount: Integer;
var
  i: Integer;
  imgData: TAI_Image;
begin
  Result := 0;
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      inc(Result, imgData.DetectorDefineList.Count);
    end;
end;

function TAI_ImageList.DetectorDefinePartCount: Integer;
var
  i, j: Integer;
  imgData: TAI_Image;
begin
  Result := 0;
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
          inc(Result, imgData.DetectorDefineList[i].Part.Count);
    end;
end;

function TAI_ImageList.ExtractDetectorDefineAsSnapshot: TMemoryRaster2DArray;
var
  i, j: Integer;
  imgData: TAI_Image;
  DetDef: TAI_DetectorDefine;
  mr: TMemoryRaster;
  hList: THashObjectList;
  mrList: TMemoryRasterList;
  pl: TPascalStringList;
begin
  hList := THashObjectList.Create(True);
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            begin
              mr := NewRaster();
              mr.UserToken := DetDef.Token;
              mr.SetWorkMemory(DetDef.Owner.Raster);
              if not hList.Exists(DetDef.Token) then
                  hList.FastAdd(DetDef.Token, TMemoryRasterList.Create);
              if TMemoryRasterList(hList[DetDef.Token]).IndexOf(mr) < 0 then
                  TMemoryRasterList(hList[DetDef.Token]).Add(mr);
            end;
        end;
    end;

  // process sequence
  SetLength(Result, hList.Count);
  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := TMemoryRasterList(hList[pl[i]]);
      SetLength(Result[i], mrList.Count);
      for j := 0 to mrList.Count - 1 do
          Result[i, j] := mrList[j];
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

function TAI_ImageList.ExtractDetectorDefineAsPrepareRaster(SS_width, SS_height: Integer): TMemoryRaster2DArray;
var
  i, j: Integer;
  imgData: TAI_Image;
  DetDef: TAI_DetectorDefine;
  mr: TMemoryRaster;
  hList: THashObjectList;
  mrList: TMemoryRasterList;
  pl: TPascalStringList;
begin
  hList := THashObjectList.Create(True);
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            if not DetDef.PrepareRaster.Empty then
              begin
                mr := NewRaster();
                mr.ZoomFrom(DetDef.PrepareRaster, SS_width, SS_height);
                mr.UserToken := DetDef.Token;
                if not hList.Exists(DetDef.Token) then
                    hList.FastAdd(DetDef.Token, TMemoryRasterList.Create);
                TMemoryRasterList(hList[DetDef.Token]).Add(mr);
              end;
        end;
    end;

  // process sequence
  SetLength(Result, hList.Count);
  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := TMemoryRasterList(hList[pl[i]]);
      SetLength(Result[i], mrList.Count);
      for j := 0 to mrList.Count - 1 do
          Result[i, j] := mrList[j];
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

function TAI_ImageList.ExtractDetectorDefineAsScaleSpace(SS_width, SS_height: Integer): TMemoryRaster2DArray;
var
  i, j: Integer;
  imgData: TAI_Image;
  DetDef: TAI_DetectorDefine;
  mr: TMemoryRaster;
  hList: THashObjectList;
  mrList: TMemoryRasterList;
  pl: TPascalStringList;
begin
  hList := THashObjectList.Create(True);
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            begin
              mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_width, SS_height);
              mr.UserToken := DetDef.Token;
              if not hList.Exists(DetDef.Token) then
                  hList.FastAdd(DetDef.Token, TMemoryRasterList.Create);
              TMemoryRasterList(hList[DetDef.Token]).Add(mr);
            end;
        end;
    end;

  // process sequence
  SetLength(Result, hList.Count);
  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := TMemoryRasterList(hList[pl[i]]);
      SetLength(Result[i], mrList.Count);
      for j := 0 to mrList.Count - 1 do
          Result[i, j] := mrList[j];
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

function TAI_ImageList.FoundNoTokenDetectorDefine(output: TMemoryRaster): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Count - 1 do
    if Items[i].FoundNoTokenDetectorDefine(output, DEColor(1, 0, 0, 0.5)) then
        exit;
  Result := False;
end;

function TAI_ImageList.FoundNoTokenDetectorDefine: Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Count - 1 do
    if Items[i].FoundNoTokenDetectorDefine then
        exit;
  Result := False;
end;

function TAI_ImageList.Tokens: TArrayPascalString;
var
  i, j: Integer;
  imgData: TAI_Image;
  DetDef: TAI_DetectorDefine;
  hList: THashList;
begin
  hList := THashList.Create;
  for i := 0 to Count - 1 do
    begin
      imgData := Items[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if DetDef.Token <> '' then
            if not hList.Exists(DetDef.Token) then
                hList.Add(DetDef.Token, nil, False);
        end;
    end;

  hList.GetNameList(Result);
  disposeObject(hList);
end;

function TAI_ImageList.ExistsToken(Token: TPascalString): Boolean;
begin
  Result := GetTokenCount(Token) > 0;
end;

function TAI_ImageList.GetTokenCount(Token: TPascalString): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].GetTokenCount(Token));
end;

constructor TAI_ImageMatrix.Create;
begin
  inherited Create;
end;

destructor TAI_ImageMatrix.Destroy;
begin
  inherited Destroy;
end;

procedure TAI_ImageMatrix.SaveToStream(stream: TCoreClassStream);
type
  PSaveRec = ^TSaveRec;

  TSaveRec = record
    fn: TPascalString;
    m64: TMemoryStream64;
  end;

var
  dbEng: TObjectDataManager;
  fPos: Int64;
  PrepareSave: array of TSaveRec;
  FinishSave: array of PSaveRec;

{$IFDEF parallel}
{$IFDEF FPC}
  procedure fpc_Prepare_Save_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  var
    p: PSaveRec;
  begin
    p := @PrepareSave[pass];
    p^.m64 := TMemoryStream64.CustomCreate(1024 * 1024);
    Items[pass].SaveToStream(p^.m64, True, True);
    p^.fn := Items[pass].FileInfo.TrimChar(#32#9);
    if (p^.fn.Len = 0) then
        p^.fn := umlStreamMD5String(p^.m64);
    p^.fn := p^.fn + C_ImageList_Ext;
    FinishSave[pass] := p;
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure Prepare_Save();
  var
    i: Integer;
    p: PSaveRec;
  begin
    for i := 0 to Count - 1 do
      begin
        p := @PrepareSave[i];
        p^.m64 := TMemoryStream64.CustomCreate(1024 * 1024);
        Items[i].SaveToStream(p^.m64, True, True);
        p^.fn := Items[i].FileInfo.TrimChar(#32#9);
        if (p^.fn.Len = 0) then
            p^.fn := umlStreamMD5String(p^.m64);
        p^.fn := p^.fn + C_ImageList_Ext;
        FinishSave[i] := p;
      end;
  end;

{$ENDIF parallel}
  procedure Save();
  var
    i: Integer;
    p: PSaveRec;
    itmHnd: TItemHandle;
  begin
    for i := 0 to Count - 1 do
      begin
        while FinishSave[i] = nil do
            TCoreClassThread.Sleep(1);

        p := FinishSave[i];

        dbEng.ItemFastCreate(fPos, p^.fn, 'ImageMatrix', itmHnd);
        dbEng.ItemWrite(itmHnd, p^.m64.Size, p^.m64.memory^);
        dbEng.ItemClose(itmHnd);
        disposeObject(p^.m64);
        p^.fn := '';
      end;
  end;

begin
  dbEng := TObjectDataManagerOfCache.CreateAsStream(stream, '', DBMarshal.ID, False, True, False);
  fPos := dbEng.RootField;

  SetLength(PrepareSave, Count);
  SetLength(FinishSave, Count);

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@fpc_Prepare_Save_ParallelFor, 0, Count - 1);
  Save();
{$ELSE FPC}
  TParallel.for(0, Count - 1, procedure(pass: Integer)
    var
      p: PSaveRec;
    begin
      p := @PrepareSave[pass];
      p^.m64 := TMemoryStream64.CustomCreate(1024 * 1024);
      Items[pass].SaveToStream(p^.m64, True, True);
      p^.fn := Items[pass].FileInfo.TrimChar(#32#9);
      if (p^.fn.Len = 0) then
          p^.fn := umlStreamMD5String(p^.m64);
      p^.fn := p^.fn + C_ImageList_Ext;
      FinishSave[pass] := p;
    end);
  Save();
{$ENDIF FPC}
{$ELSE parallel}
  Prepare_Save();
  Save();
{$ENDIF parallel}
  disposeObject(dbEng);
  DoStatus('Save Image Matrix done.');
end;

procedure TAI_ImageMatrix.LoadFromStream(stream: TCoreClassStream);
type
  PLoadRec = ^TLoadRec;

  TLoadRec = record
    fn: TPascalString;
    m64: TMemoryStream64;
    imgList: TAI_ImageList;
  end;

var
  dbEng: TObjectDataManager;
  fPos: Int64;
  PrepareLoadBuffer: TCoreClassList;
  itmSR: TItemSearch;

  procedure PrepareMemory;
  var
    itmHnd: TItemHandle;
    p: PLoadRec;
  begin
    new(p);
    p^.fn := umlChangeFileExt(itmSR.name, '');
    dbEng.ItemFastOpen(itmSR.HeaderPOS, itmHnd);
    p^.m64 := TMemoryStream64.Create;
    p^.m64.Size := itmHnd.Item.Size;
    dbEng.ItemRead(itmHnd, itmHnd.Item.Size, p^.m64.memory^);
    dbEng.ItemClose(itmHnd);

    p^.imgList := TAI_ImageList.Create;
    Add(p^.imgList);
    PrepareLoadBuffer.Add(p);
  end;

{$IFDEF parallel}
{$IFDEF FPC}
  procedure Load_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  var
    p: PLoadRec;
  begin
    p := PrepareLoadBuffer[pass];
    p^.m64.Position := 0;
    p^.imgList.LoadFromStream(p^.m64);
    p^.imgList.FileInfo := p^.fn;
    disposeObject(p^.m64);
    p^.fn := '';
    Dispose(p);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure Load_For();
  var
    i: Integer;
    p: PLoadRec;
  begin
    for i := 0 to PrepareLoadBuffer.Count - 1 do
      begin
        p := PrepareLoadBuffer[i];
        p^.m64.Position := 0;
        p^.imgList.LoadFromStream(p^.m64);
        p^.imgList.FileInfo := p^.fn;
        disposeObject(p^.m64);
        p^.fn := '';
        Dispose(p);
      end;
  end;
{$ENDIF parallel}


begin
  dbEng := TObjectDataManagerOfCache.CreateAsStream(stream, '', DBMarshal.ID, True, False, False);
  fPos := dbEng.RootField;
  PrepareLoadBuffer := TCoreClassList.Create;

  if dbEng.ItemFastFindFirst(fPos, '', itmSR) then
    begin
      repeat
        if umlMultipleMatch('*' + C_ImageList_Ext, itmSR.name) then
            PrepareMemory;
      until not dbEng.ItemFindNext(itmSR);
    end;
  disposeObject(dbEng);

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Load_ParallelFor, 0, PrepareLoadBuffer.Count - 1);
{$ELSE FPC}
  TParallel.for(0, PrepareLoadBuffer.Count - 1, procedure(pass: Integer)
    var
      p: PLoadRec;
    begin
      p := PrepareLoadBuffer[pass];
      p^.m64.Position := 0;
      p^.imgList.LoadFromStream(p^.m64);
      p^.imgList.FileInfo := p^.fn;
      disposeObject(p^.m64);
      p^.fn := '';
      Dispose(p);
    end);
{$ENDIF FPC}
{$ELSE parallel}
  Load_For();
{$ENDIF parallel}
  disposeObject(PrepareLoadBuffer);
  DoStatus('Load Image Matrix done.');
end;

procedure TAI_ImageMatrix.SaveToFile(fileName: SystemString);
var
  fs: TCoreClassFileStream;
begin
  DoStatus('save Image Matrix: %s', [fileName]);
  fs := TCoreClassFileStream.Create(fileName, fmCreate);
  SaveToStream(fs);
  disposeObject(fs);
end;

procedure TAI_ImageMatrix.LoadFromFile(fileName: SystemString);
var
  fs: TCoreClassFileStream;
begin
  DoStatus('loading Image Matrix: %s', [fileName]);
  fs := TCoreClassFileStream.Create(fileName, fmOpenRead or fmShareDenyWrite);
  LoadFromStream(fs);
  disposeObject(fs);
end;

procedure TAI_ImageMatrix.ClearPrepareRaster;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].ClearPrepareRaster;
end;

procedure TAI_ImageMatrix.SearchAndAddImageList(rootPath, filter: SystemString; includeSubdir, LoadImg: Boolean);

  procedure ProcessImg(fn, Prefix: TPascalString);
  var
    imgList: TAI_ImageList;
  begin
    DoStatus('%s (%s)', [fn.Text, Prefix.Text]);
    imgList := TAI_ImageList.Create;
    imgList.LoadFromFile(fn, LoadImg);
    imgList.FileInfo := Prefix;
    Add(imgList);
  end;

  procedure ProcessPath(ph, Prefix: TPascalString);
  var
    fl, dl: TPascalStringList;
    i: Integer;
  begin
    fl := TPascalStringList.Create;
    umlGetFileList(ph, fl);

    for i := 0 to fl.Count - 1 do
      if umlMultipleMatch(filter, fl[i]) then
        begin
          if Prefix.Len > 0 then
              ProcessImg(umlCombineFileName(ph, fl[i]), Prefix + '.' + umlChangeFileExt(fl[i], ''))
          else
              ProcessImg(umlCombineFileName(ph, fl[i]), umlChangeFileExt(fl[i], ''));
        end;

    disposeObject(fl);

    if includeSubdir then
      begin
        dl := TPascalStringList.Create;
        umlGetDirList(ph, dl);
        for i := 0 to dl.Count - 1 do
          begin
            if Prefix.Len > 0 then
                ProcessPath(umlCombinePath(ph, dl[i]), Prefix + '.' + dl[i])
            else
                ProcessPath(umlCombinePath(ph, dl[i]), dl[i]);
          end;
        disposeObject(dl);
      end;
  end;

begin
  ProcessPath(rootPath, '')
end;

procedure TAI_ImageMatrix.Scale(f: TGeoFloat);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Scale(f);
end;

procedure TAI_ImageMatrix.Build_PrepareDataset(outputPath: SystemString);
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      Items[i].Build_PrepareDataset(outputPath);
end;

procedure TAI_ImageMatrix.Build_XML(TokenFilter: TPascalString; includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList);
  function num_2(num: Integer): SystemString;
  begin
    if num < 10 then
        Result := PFormat('0%d', [num])
    else
        Result := PFormat('%d', [num]);
  end;

  procedure SaveFileInfo(fn: TPascalString);
  begin
    if BuildFileList <> nil then
        BuildFileList.Add(fn);
  end;

  procedure ProcessBody(imgList: TAI_ImageList; body: TPascalStringList; output_path: SystemString);
  var
    i, j, k: Integer;
    imgData: TAI_Image;
    DetDef: TAI_DetectorDefine;
    m64: TMemoryStream64;
    m5: TMD5;
    n: SystemString;
    v_p: PVec2;
  begin
    for i := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[i];
        if (imgData.DetectorDefineList.Count = 0) or (not imgData.ExistsToken(TokenFilter)) then
            continue;

        m64 := TMemoryStream64.Create;
        imgData.Raster.SaveToBmp24Stream(m64);
        m5 := umlStreamMD5(m64);
        n := umlCombineFileName(output_path, Prefix + umlMD5ToStr(m5) + '.bmp');
        if not umlFileExists(n) then
          begin
            m64.SaveToFile(n);
            SaveFileInfo(n);
          end;
        disposeObject(m64);

        body.Add(PFormat(' <image file='#39'%s'#39'>', [umlGetFileName(n).Text]));
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if umlMultipleMatch(TokenFilter, DetDef.Token) then
              begin
                body.Add(PFormat(
                  '  <box top='#39'%d'#39' left='#39'%d'#39' width='#39'%d'#39' height='#39'%d'#39'>',
                  [DetDef.R.Top, DetDef.R.Left, DetDef.R.width, DetDef.R.height]));

                if includeLabel and (DetDef.Token.Len > 0) then
                    body.Add(PFormat('    <label>%s</label>', [DetDef.Token.Text]));

                if includePart then
                  begin
                    for k := 0 to DetDef.Part.Count - 1 do
                      begin
                        v_p := DetDef.Part[k];
                        body.Add(PFormat(
                          '    <part name='#39'%s'#39' x='#39'%d'#39' y='#39'%d'#39'/>',
                          [num_2(k), Round(v_p^[0]), Round(v_p^[1])]));
                      end;
                  end;

                body.Add('  </box>');
              end;
          end;
        body.Add(' </image>');
      end;
  end;

var
  body: TPascalStringList;
  output_path, n: SystemString;
  m64: TMemoryStream64;
  i: Integer;
  s_body: SystemString;
begin
  body := TPascalStringList.Create;
  output_path := umlGetFilePath(build_output_file);
  umlCreateDirectory(output_path);
  umlSetCurrentPath(output_path);

  for i := 0 to Count - 1 do
      ProcessBody(Items[i], body, output_path);

  s_body := body.Text;
  disposeObject(body);

  m64 := TMemoryStream64.Create;
  Build_XML_Style(m64);
  n := umlCombineFileName(output_path, Prefix + umlChangeFileExt(umlGetFileName(build_output_file), '.xsl'));
  m64.SaveToFile(n);
  SaveFileInfo(n);
  disposeObject(m64);

  m64 := TMemoryStream64.Create;
  Build_XML_Dataset(umlGetFileName(n), datasetName, comment, s_body, m64);
  m64.SaveToFile(build_output_file);
  SaveFileInfo(build_output_file);
  disposeObject(m64);
end;

procedure TAI_ImageMatrix.Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file, Prefix: SystemString; BuildFileList: TPascalStringList);
begin
  Build_XML('', includeLabel, includePart, datasetName, comment, build_output_file, Prefix, BuildFileList);
end;

procedure TAI_ImageMatrix.Build_XML(includeLabel, includePart: Boolean; datasetName, comment, build_output_file: SystemString);
begin
  Build_XML(includeLabel, includePart, datasetName, comment, build_output_file, '', nil);
end;

function TAI_ImageMatrix.ImageCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].Count);
end;

function TAI_ImageMatrix.DetectorDefineCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].DetectorDefineCount);
end;

function TAI_ImageMatrix.DetectorDefinePartCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].DetectorDefinePartCount);
end;

function TAI_ImageMatrix.ExtractDetectorDefineAsSnapshot: TMemoryRaster2DArray;
  procedure BuildHashList(imgList: TAI_ImageList; hList: THashObjectList);
  var
    i, j: Integer;
    imgData: TAI_Image;
    DetDef: TAI_DetectorDefine;
    mr: TMemoryRaster;
  begin
    for i := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[i];
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              begin
                mr := NewRaster();
                mr.SetWorkMemory(DetDef.Owner.Raster);
                mr.UserToken := DetDef.Token;
                if not hList.Exists(DetDef.Token) then
                    hList.FastAdd(DetDef.Token, TMemoryRasterList.Create);
                if TMemoryRasterList(hList[DetDef.Token]).IndexOf(mr) < 0 then
                    TMemoryRasterList(hList[DetDef.Token]).Add(mr);
              end;
          end;
      end;
  end;

var
  i, j: Integer;
  mr: TMemoryRaster;
  hList: THashObjectList;
  mrList: TMemoryRasterList;
  pl: TPascalStringList;
begin
  hList := THashObjectList.Create(True);
  for i := 0 to Count - 1 do
      BuildHashList(Items[i], hList);

  // process sequence
  SetLength(Result, hList.Count);
  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := TMemoryRasterList(hList[pl[i]]);
      SetLength(Result[i], mrList.Count);
      for j := 0 to mrList.Count - 1 do
          Result[i, j] := mrList[j];
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

function TAI_ImageMatrix.ExtractDetectorDefineAsPrepareRaster(SS_width, SS_height: Integer): TMemoryRaster2DArray;
  procedure BuildHashList(imgList: TAI_ImageList; hList: THashObjectList);
  var
    i, j: Integer;
    imgData: TAI_Image;
    DetDef: TAI_DetectorDefine;
    mr: TMemoryRaster;
  begin
    for i := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[i];
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              if not DetDef.PrepareRaster.Empty then
                begin
                  mr := NewRaster();
                  mr.ZoomFrom(DetDef.PrepareRaster, SS_width, SS_height);
                  mr.UserToken := DetDef.Token;
                  if not hList.Exists(DetDef.Token) then
                      hList.FastAdd(DetDef.Token, TMemoryRasterList.Create);
                  TMemoryRasterList(hList[DetDef.Token]).Add(mr);
                end;
          end;
      end;
  end;

var
  i, j: Integer;
  mr: TMemoryRaster;
  hList: THashObjectList;
  mrList: TMemoryRasterList;
  pl: TPascalStringList;
begin
  hList := THashObjectList.Create(True);
  for i := 0 to Count - 1 do
      BuildHashList(Items[i], hList);

  // process sequence
  SetLength(Result, hList.Count);
  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := TMemoryRasterList(hList[pl[i]]);
      SetLength(Result[i], mrList.Count);
      for j := 0 to mrList.Count - 1 do
          Result[i, j] := mrList[j];
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

function TAI_ImageMatrix.ExtractDetectorDefineAsScaleSpace(SS_width, SS_height: Integer): TMemoryRaster2DArray;
  procedure BuildHashList(imgList: TAI_ImageList; hList: THashObjectList);
  var
    i, j: Integer;
    imgData: TAI_Image;
    DetDef: TAI_DetectorDefine;
    mr: TMemoryRaster;
  begin
    for i := 0 to imgList.Count - 1 do
      begin
        imgData := imgList[i];
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              begin
                mr := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_width, SS_height);
                mr.UserToken := DetDef.Token;
                if not hList.Exists(DetDef.Token) then
                    hList.FastAdd(DetDef.Token, TMemoryRasterList.Create);
                TMemoryRasterList(hList[DetDef.Token]).Add(mr);
              end;
          end;
      end;
  end;

var
  i, j: Integer;
  mr: TMemoryRaster;
  hList: THashObjectList;
  mrList: TMemoryRasterList;
  pl: TPascalStringList;
begin
  hList := THashObjectList.Create(True);
  for i := 0 to Count - 1 do
      BuildHashList(Items[i], hList);

  // process sequence
  SetLength(Result, hList.Count);
  pl := TPascalStringList.Create;
  hList.GetNameList(pl);
  for i := 0 to pl.Count - 1 do
    begin
      mrList := TMemoryRasterList(hList[pl[i]]);
      SetLength(Result[i], mrList.Count);
      for j := 0 to mrList.Count - 1 do
          Result[i, j] := mrList[j];
    end;

  disposeObject(pl);
  disposeObject(hList);
end;

function TAI_ImageMatrix.FoundNoTokenDetectorDefine(output: TMemoryRaster): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Count - 1 do
    if Items[i].FoundNoTokenDetectorDefine(output) then
        exit;
  Result := False;
end;

function TAI_ImageMatrix.FoundNoTokenDetectorDefine: Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 0 to Count - 1 do
    if Items[i].FoundNoTokenDetectorDefine then
        exit;
  Result := False;
end;

function TAI_ImageMatrix.Tokens: TArrayPascalString;
var
  hList: THashList;

  procedure get_img_tokens(imgL: TAI_ImageList);
  var
    i, j: Integer;
    imgData: TAI_Image;
    DetDef: TAI_DetectorDefine;
  begin
    for i := 0 to imgL.Count - 1 do
      begin
        imgData := imgL[i];
        for j := 0 to imgData.DetectorDefineList.Count - 1 do
          begin
            DetDef := imgData.DetectorDefineList[j];
            if DetDef.Token <> '' then
              if not hList.Exists(DetDef.Token) then
                  hList.Add(DetDef.Token, nil, False);
          end;
      end;

  end;

  procedure do_run;
  var
    i: Integer;
  begin
    for i := 0 to Count - 1 do
        get_img_tokens(Items[i]);
  end;

begin
  hList := THashList.Create;
  do_run;
  hList.GetNameList(Result);
  disposeObject(hList);
end;

function TAI_ImageMatrix.ExistsToken(Token: TPascalString): Boolean;
begin
  Result := GetTokenCount(Token) > 0;
end;

function TAI_ImageMatrix.GetTokenCount(Token: TPascalString): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
      inc(Result, Items[i].GetTokenCount(Token));
end;

constructor TOneStepList.Create;
begin
  inherited Create;
  Critical := TSoftCritical.Create;
end;

destructor TOneStepList.Destroy;
begin
  Clear;
  disposeObject(Critical);
  inherited Destroy;
end;

procedure TOneStepList.Delete(index: Integer);
begin
  Critical.Acquire;
  try
    Dispose(Items[index]);
    inherited Delete(index);
  finally
      Critical.Release;
  end;
end;

procedure TOneStepList.Clear;
var
  i: Integer;
begin
  Critical.Acquire;
  try
    for i := 0 to Count - 1 do
        Dispose(Items[i]);
    inherited Clear;
  finally
      Critical.Release;
  end;
end;

procedure TOneStepList.AddStep(one_step_calls: UInt64; average_loss, learning_rate: Double);
var
  p: POneStep;
begin
  new(p);
  p^.StepTime := umlNow();
  p^.one_step_calls := one_step_calls;
  p^.average_loss := average_loss;
  p^.learning_rate := learning_rate;
  Critical.Acquire;
  try
      Add(p);
  finally
      Critical.Release;
  end;
end;

procedure TOneStepList.SaveToStream(stream: TMemoryStream64);
var
  i: Integer;
  p: POneStep;
begin
  Critical.Acquire;
  try
    stream.WriteInt32(Count);
    for i := 0 to Count - 1 do
      begin
        p := Items[i];
        stream.WritePtr(p, SizeOf(TOneStep));
      end;
  finally
      Critical.Release;
  end;
end;

procedure TOneStepList.LoadFromStream(stream: TMemoryStream64);
var
  c, i: Integer;
  p: POneStep;
begin
  Clear;
  Critical.Acquire;
  try
    c := stream.ReadInt32;
    for i := 0 to c - 1 do
      begin
        new(p);
        stream.ReadPtr(p, SizeOf(TOneStep));
        Add(p);
      end;
  finally
      Critical.Release;
  end;
end;

constructor TAlignment.Create(OwnerAI: TAI);
begin
  inherited Create;
  AI := OwnerAI;
end;

destructor TAlignment.Destroy;
begin
  inherited Destroy;
end;

procedure TAlignment_Face.Alignment(imgList: TAI_ImageList);
var
  mr: TMemoryRaster;
  face_hnd: TFACE_Handle;
  i, j, k: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
  sp_desc: TSP_Desc;
  r1, r2: TRectV2;
begin
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      img.Clear;

      // full detector do scale 2x size
      mr := NewRaster();
      mr.ZoomFrom(img.Raster, img.Raster.width * 2, img.Raster.height * 2);
      // extract face
      face_hnd := AI.Face_Detector_All(mr);
      // dispose raster
      disposeObject(mr);

      if face_hnd <> nil then
        begin
          for j := 0 to AI.Face_chips_num(face_hnd) - 1 do
            begin
              sp_desc := AI.Face_Shape(face_hnd, j);
              if (length(sp_desc) > 0) then
                begin
                  for k := 0 to length(sp_desc) - 1 do
                    begin
                      sp_desc[k].x := Round(sp_desc[k].x * 0.5);
                      sp_desc[k].y := Round(sp_desc[k].y * 0.5);
                    end;
                  r1 := RectV2(AI.Face_Rect(face_hnd, j));
                  r1 := ForwardRect(RectMul(r1, 0.5));
                  r2 := ForwardRect(GetSPBound(sp_desc, 0.1));

                  if InRect(sp_desc, img.Raster.BoundsRectV2) then
                    begin
                      DetDef := TAI_DetectorDefine.Create(img);
                      img.DetectorDefineList.Add(DetDef);
                      disposeObject(DetDef.PrepareRaster);
                      DetDef.PrepareRaster := AI.Face_chips(face_hnd, j);
                      SPToVec(sp_desc, DetDef.Part);

                      DetDef.R := MakeRect(BoundRect(r1, r2));
                    end;
                  SetLength(sp_desc, 0);
                end;
            end;

          AI.Face_Close(face_hnd);
        end;
    end;
end;

procedure TAlignment_FastFace.Alignment(imgList: TAI_ImageList);
var
  face_hnd: TFACE_Handle;
  i, j, k: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
  sp_desc: TSP_Desc;
  r1, r2: TRectV2;
begin
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      img.Clear;

      // extract face
      face_hnd := AI.Face_Detector_All(img.Raster);

      if face_hnd <> nil then
        begin
          for j := 0 to AI.Face_chips_num(face_hnd) - 1 do
            begin
              sp_desc := AI.Face_Shape(face_hnd, j);
              if (length(sp_desc) > 0) then
                begin
                  r1 := RectV2(AI.Face_Rect(face_hnd, j));
                  r2 := ForwardRect(GetSPBound(sp_desc, 0.1));

                  if InRect(sp_desc, img.Raster.BoundsRectV2) then
                    begin
                      DetDef := TAI_DetectorDefine.Create(img);
                      img.DetectorDefineList.Add(DetDef);
                      disposeObject(DetDef.PrepareRaster);
                      DetDef.PrepareRaster := AI.Face_chips(face_hnd, j);
                      SPToVec(sp_desc, DetDef.Part);

                      DetDef.R := MakeRect(BoundRect(r1, r2));
                    end;
                  SetLength(sp_desc, 0);
                end;
            end;

          AI.Face_Close(face_hnd);
        end;
    end;
end;

procedure TAlignment_ScaleSpace.Alignment(imgList: TAI_ImageList);
var
  i, j: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
begin
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      for j := 0 to img.DetectorDefineList.Count - 1 do
        begin
          DetDef.R := RectScaleSpace(DetDef.R, SS_width, SS_height);
          DetDef.R := CalibrationRectInRect(DetDef.R, DetDef.Owner.Raster.BoundsRect);

          DetDef := img.DetectorDefineList[j];
          disposeObject(DetDef.PrepareRaster);
          DetDef.PrepareRaster := DetDef.Owner.Raster.BuildAreaOffsetScaleSpace(DetDef.R, SS_width, SS_height);
        end;
    end;
end;

procedure TAlignment_OD.Alignment(imgList: TAI_ImageList);
var
  i, j: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
  od_desc: TOD_Desc;
  mr: TMemoryRaster;
begin
  if od_hnd = nil then
      exit;
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      img.Clear;
      mr := NewRaster();
      mr.ZoomFrom(img.Raster, img.Raster.width * 2, img.Raster.height * 2);
      od_desc := AI.OD_Process(od_hnd, mr, 1024);
      disposeObject(mr);
      for j := 0 to length(od_desc) - 1 do
        begin
          DetDef := TAI_DetectorDefine.Create(img);
          DetDef.R := MakeRect(RectMul(RectV2(od_desc[j]), 0.5));
          img.DetectorDefineList.Add(DetDef);
        end;
    end;
end;

procedure TAlignment_FastOD.Alignment(imgList: TAI_ImageList);
var
  i, j: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
  od_desc: TOD_Desc;
begin
  if od_hnd = nil then
      exit;
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      img.Clear;
      od_desc := AI.OD_Process(od_hnd, img.Raster, 1024);
      for j := 0 to length(od_desc) - 1 do
        begin
          DetDef := TAI_DetectorDefine.Create(img);
          DetDef.R := Rect(od_desc[j]);
          img.DetectorDefineList.Add(DetDef);
        end;
    end;
end;

procedure TAlignment_OD_Marshal.Alignment(imgList: TAI_ImageList);
var
  i, j: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
  od_desc: TOD_Marshal_Desc;
  mr: TMemoryRaster;
begin
  if od_hnd = nil then
      exit;
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      img.Clear;
      mr := NewRaster();
      mr.ZoomFrom(img.Raster, img.Raster.width * 2, img.Raster.height * 2);
      od_desc := AI.OD_Marshal_Process(od_hnd, mr);
      disposeObject(mr);
      for j := 0 to length(od_desc) - 1 do
        begin
          DetDef := TAI_DetectorDefine.Create(img);
          DetDef.R := MakeRect(RectMul(od_desc[j].R, 0.5));
          DetDef.Token := od_desc[j].Token;
          img.DetectorDefineList.Add(DetDef);
        end;
    end;
end;

procedure TAlignment_FastOD_Marshal.Alignment(imgList: TAI_ImageList);
var
  i, j: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
  od_desc: TOD_Marshal_Desc;
begin
  if od_hnd = nil then
      exit;
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      img.Clear;
      od_desc := AI.OD_Marshal_Process(od_hnd, img.Raster);
      for j := 0 to length(od_desc) - 1 do
        begin
          DetDef := TAI_DetectorDefine.Create(img);
          DetDef.R := MakeRect(od_desc[j].R);
          DetDef.Token := od_desc[j].Token;
          img.DetectorDefineList.Add(DetDef);
        end;
    end;
end;

procedure TAlignment_SP.Alignment(imgList: TAI_ImageList);
var
  i, j: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
  sp_desc: TSP_Desc;
begin
  if sp_hnd = nil then
      exit;
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      for j := 0 to img.DetectorDefineList.Count - 1 do
        begin
          DetDef := img.DetectorDefineList[j];

          sp_desc := AI.SP_Process(sp_hnd, DetDef.Owner.Raster, AIRect(DetDef.R), 1024);
          if length(sp_desc) > 0 then
            begin
              DetDef.Part.Clear;
              SPToVec(sp_desc, DetDef.Part);
              disposeObject(DetDef.PrepareRaster);
              SetLength(sp_desc, 0);
            end;
        end;
    end;
end;

procedure TAlignment_MMOD.Alignment(imgList: TAI_ImageList);
var
  i, j: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
  mmod_desc: TMMOD_Desc;
  mr: TMemoryRaster;
begin
  if MMOD_hnd = nil then
      exit;
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      img.Clear;
      mr := NewRaster();
      mr.ZoomFrom(img.Raster, img.Raster.width * 2, img.Raster.height * 2);
      mmod_desc := AI.MMOD_DNN_Process(MMOD_hnd, mr);
      disposeObject(mr);
      for j := 0 to length(mmod_desc) - 1 do
        begin
          DetDef := TAI_DetectorDefine.Create(img);
          DetDef.R := MakeRect(RectMul(mmod_desc[j].R, 0.5));
          DetDef.Token := mmod_desc[j].Token;
          img.DetectorDefineList.Add(DetDef);
        end;
    end;
end;

procedure TAlignment_FastMMOD.Alignment(imgList: TAI_ImageList);
var
  i, j: Integer;
  img: TAI_Image;
  DetDef: TAI_DetectorDefine;
  mmod_desc: TMMOD_Desc;
begin
  if MMOD_hnd = nil then
      exit;
  for i := 0 to imgList.Count - 1 do
    begin
      img := imgList[i];
      img.Clear;
      mmod_desc := AI.MMOD_DNN_Process(MMOD_hnd, img.Raster);
      for j := 0 to length(mmod_desc) - 1 do
        begin
          DetDef := TAI_DetectorDefine.Create(img);
          DetDef.R := MakeRect(mmod_desc[j].R);
          DetDef.Token := mmod_desc[j].Token;
          img.DetectorDefineList.Add(DetDef);
        end;
    end;
end;

constructor TAI.Create;
begin
  inherited Create;
  AI_Ptr := nil;
  face_sp_hnd := nil;
  TrainingControl.pause := 0;
  TrainingControl.stop := 0;
  Critical := TSoftCritical.Create;

  Parallel_OD_Hnd := nil;
  Parallel_OD_Marshal_Hnd := nil;
  Parallel_SP_Hnd := nil;
  Parallel_MDNN_Hnd := nil;
  Parallel_MMOD_Hnd := nil;
  Parallel_RNIC_Hnd := nil;

{$IFDEF FPC}
  rootPath := AI_Configure_Path;
{$ELSE FPC}
  rootPath := System.IOUtils.TPath.GetTempPath;
{$ENDIF FPC}
  rootPath := umlCombinePath(rootPath, 'Z_AI_Temp');
  umlCreateDirectory(rootPath);

  Last_training_average_loss := 0;
  Last_training_learning_rate := 0;
end;

class function TAI.OpenEngine(libFile: SystemString): TAI;
begin
  Result := TAI.Create;
  Result.AI_Ptr := Load_ZAI(libFile);
  if Result.AI_Ptr = nil then
      Result.AI_Ptr := Load_ZAI(AI_Engine_Library);
end;

class function TAI.OpenEngine(lib_p: Pointer): TAI;
begin
  Result := TAI.Create;
  Result.AI_Ptr := lib_p;
end;

class function TAI.OpenEngine: TAI;
begin
  Result := TAI.Create;
  Result.AI_Ptr := Load_ZAI(AI_Engine_Library);
end;

destructor TAI.Destroy;
begin
  if face_sp_hnd <> nil then
      SP_Close(face_sp_hnd);
  if Parallel_OD_Hnd <> nil then
      OD_Close(Parallel_OD_Hnd);
  if Parallel_OD_Marshal_Hnd <> nil then
      OD_Marshal_Close(Parallel_OD_Marshal_Hnd);
  if Parallel_SP_Hnd <> nil then
      SP_Close(Parallel_SP_Hnd);
  if Parallel_MDNN_Hnd <> nil then
      Metric_ResNet_Close(Parallel_MDNN_Hnd);
  if Parallel_MMOD_Hnd <> nil then
      MMOD_DNN_Close(Parallel_MMOD_Hnd);
  if Parallel_RNIC_Hnd <> nil then
      RNIC_Close(Parallel_RNIC_Hnd);

  disposeObject(Critical);
  inherited Destroy;
end;

procedure TAI.DrawOD(od_hnd: TOD_Handle; Raster: TMemoryRaster; color: TDEColor);
var
  od_desc: TOD_Desc;
  i: Integer;
  d: TDrawEngine;
  dt: TTimeTick;
begin
  dt := GetTimeTick();
  od_desc := OD_Process(od_hnd, Raster, 1024);
  dt := GetTimeTick() - dt;
  d := TDrawEngine.Create;
  d.ViewOptions := [];
  d.Rasterization.memory.SetWorkMemory(Raster);
  d.SetSize(Raster);
  for i := 0 to length(od_desc) - 1 do
    begin
      d.DrawBox(RectV2(od_desc[i]), color, 2);
    end;
  d.BeginCaptureShadow(Vec2(1, 1), 0.9);
  d.EndCaptureShadow;
  d.Flush;
  disposeObject(d);
end;

procedure TAI.DrawODM(odm_hnd: TOD_Marshal_Handle; Raster: TMemoryRaster; color: TDEColor);
var
  odm_desc: TOD_Marshal_Desc;
  i: Integer;
  d: TDrawEngine;
  dt: TTimeTick;
begin
  dt := GetTimeTick();
  odm_desc := OD_Marshal_Process(odm_hnd, Raster);
  dt := GetTimeTick() - dt;
  d := TDrawEngine.Create;
  d.ViewOptions := [];
  d.Rasterization.memory.SetWorkMemory(Raster);
  d.SetSize(Raster);
  for i := 0 to length(odm_desc) - 1 do
    begin
      d.DrawBox(odm_desc[i].R, color, 2);
      d.BeginCaptureShadow(Vec2(1, 1), 0.9);
      d.DrawText(odm_desc[i].Token, 16, odm_desc[i].R, DEColor(1, 1, 1, 1), False);
      d.EndCaptureShadow;
    end;
  d.BeginCaptureShadow(Vec2(1, 1), 0.9);
  d.EndCaptureShadow;
  d.Flush;
  disposeObject(d);
end;

procedure TAI.DrawSP(od_hnd: TOD_Handle; sp_hnd: TSP_Handle; Raster: TMemoryRaster);
var
  od_desc: TOD_Desc;
  sp_desc: TSP_Desc;
  i, j: Integer;
  d: TDrawEngine;
begin
  od_desc := OD_Process(od_hnd, Raster, 1024);
  d := TDrawEngine.Create;
  d.ViewOptions := [];
  d.Rasterization.memory.SetWorkMemory(Raster);
  d.SetSize(Raster);
  for i := 0 to length(od_desc) - 1 do
    begin
      d.DrawBox(RectV2(od_desc[i]), DEColor(1, 0, 0, 0.9), 2);
      sp_desc := SP_Process(sp_hnd, Raster, od_desc[i], 1024);
      for j := 0 to length(sp_desc) - 1 do
          d.DrawPoint(Vec2(sp_desc[j]), DEColor(1, 0, 0, 0.9), 4, 2);
    end;
  d.Flush;
  disposeObject(d);
end;

function TAI.DrawMMOD(MMOD_hnd: TMMOD_Handle; Raster: TMemoryRaster; color: TDEColor): TMMOD_Desc;
var
  mmod_desc: TMMOD_Desc;
  i: Integer;
  d: TDrawEngine;
  dt: TTimeTick;
begin
  dt := GetTimeTick();
  mmod_desc := MMOD_DNN_Process(MMOD_hnd, Raster);
  dt := GetTimeTick() - dt;
  d := TDrawEngine.Create;
  d.ViewOptions := [];
  d.Rasterization.memory.SetWorkMemory(Raster);
  d.SetSize(Raster);
  for i := 0 to length(mmod_desc) - 1 do
    begin
      d.DrawBox(mmod_desc[i].R, color, 2);
      d.BeginCaptureShadow(Vec2(1, 1), 0.9);
      d.DrawText(mmod_desc[i].Token, 16, mmod_desc[i].R, DEColor(1, 1, 1, 1), False);
      d.EndCaptureShadow;
    end;
  d.BeginCaptureShadow(Vec2(1, 1), 0.9);
  d.EndCaptureShadow;
  d.Flush;
  disposeObject(d);
  Result := mmod_desc;
end;

procedure TAI.DrawFace(Raster: TMemoryRaster);
var
  face_hnd: TFACE_Handle;
  d: TDrawEngine;
  i: Integer;
  sp_desc: TSP_Desc;
begin
  face_hnd := Face_Detector_All(Raster, 0);
  if face_hnd = nil then
      exit;

  d := TDrawEngine.Create;
  d.ViewOptions := [];
  d.Rasterization.memory.SetWorkMemory(Raster);
  d.SetSize(Raster);

  for i := 0 to Face_Shape_num(face_hnd) - 1 do
    begin
      sp_desc := Face_Shape(face_hnd, i);
      DrawFaceSP(sp_desc, DEColor(1, 0, 0, 0.5), d);
      d.DrawBox(GetSPBound(sp_desc, 0.01), DEColor(1, 0, 0, 0.9), 2);
    end;

  d.Flush;
  disposeObject(d);
  Face_Close(face_hnd);
end;

function TAI.DrawExtractFace(Raster: TMemoryRaster): TMemoryRaster;
var
  face_hnd: TFACE_Handle;
  i: Integer;
  rp: TRectPacking;
  mr: TMemoryRaster;
  d: TDrawEngine;
begin
  face_hnd := Face_Detector_All(Raster);
  if face_hnd = nil then
      exit;

  rp := TRectPacking.Create;
  rp.Margins := 10;
  for i := 0 to Face_chips_num(face_hnd) - 1 do
    begin
      mr := Face_chips(face_hnd, i);
      rp.Add(nil, mr, mr.BoundsRectV2);
    end;
  Face_Close(face_hnd);
  rp.Build;

  d := TDrawEngine.Create;
  d.ViewOptions := [];
  Result := NewRaster();
  Result.SetSize(Round(rp.MaxWidth), Round(rp.MaxHeight));

  d.Rasterization.memory.SetWorkMemory(Result);
  d.SetSize(Result);
  d.FillBox(d.ScreenRect, DEColor(1, 1, 1, 1));

  for i := 0 to rp.Count - 1 do
    begin
      mr := rp[i]^.Data2 as TMemoryRaster;
      d.DrawTexture(mr, mr.BoundsRectV2, rp[i]^.Rect, 0, 1.0);
    end;

  d.Flush;
  disposeObject(d);

  for i := 0 to rp.Count - 1 do
      disposeObject(rp[i]^.Data2);
  disposeObject(rp);
end;

procedure TAI.Lock;
begin
  Critical.Acquire;
end;

procedure TAI.Unlock;
begin
  Critical.Release;
end;

function TAI.Busy: Boolean;
begin
  Result := Critical.Busy;
end;

procedure TAI.Training_Stop;
begin
  TrainingControl.stop := MaxInt;
end;

procedure TAI.Training_Pause;
begin
  TrainingControl.pause := MaxInt;
end;

procedure TAI.Training_Continue;
begin
  TrainingControl.pause := 0;
end;

function TAI.Prepare_RGB_Image(Raster: TMemoryRaster): TRGB_Image_Handle;
begin
  Result := nil;
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.Prepare_RGB_Image) then
      Result := AI_Ptr^.Prepare_RGB_Image(Raster.Bits, Raster.width, Raster.height);
end;

procedure TAI.Close_RGB_Image(hnd: TRGB_Image_Handle);
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.Close_RGB_Image) then
      AI_Ptr^.Close_RGB_Image(hnd);
end;

function TAI.Prepare_Matrix_Image(Raster: TMemoryRaster): TMatrix_Image_Handle;
begin
  Result := nil;
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.Prepare_Matrix_Image) then
      Result := AI_Ptr^.Prepare_Matrix_Image(Raster.Bits, Raster.width, Raster.height);
end;

procedure TAI.Close_Matrix_Image(hnd: TMatrix_Image_Handle);
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.Close_Matrix_Image) then
      AI_Ptr^.Close_Matrix_Image(hnd);
end;

function TAI.fast_surf(Raster: TMemoryRaster; const max_points: Integer; const detection_threshold: Double): TSurf_DescBuffer;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.fast_surf) then
    begin
      SetLength(Result, max_points);
      SetLength(Result, AI_Ptr^.fast_surf(Raster.Bits, Raster.width, Raster.height, max_points, detection_threshold, @Result[0]));
    end
  else
      SetLength(Result, 0);
end;

function TAI.surf_sqr(const sour, dest: PSurf_Desc): Single;
var
  f128: TGFloat_4x;
begin
  f128 := sqr_128(@sour^.desc[0], @dest^.desc[0]);
  Result := f128[0] + f128[1] + f128[2] + f128[3];
  f128 := sqr_128(@sour^.desc[32], @dest^.desc[32]);
  Result := Result + f128[0] + f128[1] + f128[2] + f128[3];
end;

function TAI.Surf_Matched(reject_ratio_sqr: Single; r1_, r2_: TMemoryRaster; sd1_, sd2_: TSurf_DescBuffer): TSurfMatchedBuffer;
var
  sd1_len, sd2_len: Integer;
  sd1, sd2: TSurf_DescBuffer;
  r1, r2: TMemoryRaster;
  l: TCoreClassList;

{$IFDEF parallel}
{$IFDEF FPC}
  procedure Nested_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  var
    m_idx, j: Integer;
    minf, next_minf: Single;
    d: Single;
    p: PSurfMatched;
  begin
    m_idx := -1;
    minf := MaxRealNumber;
    next_minf := minf;

    // find dsc1 from feat2
    for j := 0 to sd2_len - 1 do
      begin
        d := Min(surf_sqr(@sd1[pass], @sd2[j]), next_minf);
        if (d < minf) then
          begin
            next_minf := minf;
            minf := d;
            m_idx := j;
          end
        else
            next_minf := Min(next_minf, d);
      end;

    // bidirectional rejection
    if (minf > reject_ratio_sqr * next_minf) then
        exit;

    // fix m_idx
    for j := 0 to sd1_len - 1 do
      if j <> pass then
        begin
          d := Min(surf_sqr(@sd1[j], @sd2[m_idx]), next_minf);
          next_minf := Min(next_minf, d);
        end;

    // bidirectional rejection
    if (minf > reject_ratio_sqr * next_minf) then
        exit;

    new(p);
    p^.sd1 := @sd1[pass];
    p^.sd2 := @sd2[m_idx];
    p^.r1 := r1;
    p^.r2 := r2;
    LockObject(l);
    l.Add(p);
    UnLockObject(l);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure DoFor;
  var
    pass: Integer;
    m_idx, j: Integer;
    minf, next_minf: Single;
    d: Single;
    p: PSurfMatched;
  begin
    for pass := 0 to sd1_len - 1 do
      begin
        m_idx := -1;
        minf := 3.4E+38;
        next_minf := minf;

        // find dsc1 from feat2
        for j := 0 to sd2_len - 1 do
          begin
            d := Min(surf_sqr(@sd1[pass], @sd2[j]), next_minf);
            if (d < minf) then
              begin
                next_minf := minf;
                minf := d;
                m_idx := j;
              end
            else
                next_minf := Min(next_minf, d);
          end;

        // bidirectional rejection
        if (minf > reject_ratio_sqr * next_minf) then
            continue;

        // fix m_idx
        for j := 0 to sd1_len - 1 do
          if j <> pass then
            begin
              d := Min(surf_sqr(@sd1[j], @sd2[m_idx]), next_minf);
              next_minf := Min(next_minf, d);
            end;

        // bidirectional rejection
        if (minf > reject_ratio_sqr * next_minf) then
            continue;

        new(p);
        p^.sd1 := @sd1[pass];
        p^.sd2 := @sd2[m_idx];
        p^.r1 := r1;
        p^.r2 := r2;
        l.Add(p);
      end;
  end;
{$ENDIF parallel}
  procedure FillMatchInfoAndFreeTemp;
  var
    i: Integer;
    p: PSurfMatched;
  begin
    SetLength(Result, l.Count);
    for i := 0 to l.Count - 1 do
      begin
        p := PSurfMatched(l[i]);
        Result[i] := p^;
        Dispose(p);
      end;
  end;

begin
  SetLength(Result, 0);
  sd1_len := length(sd1_);
  sd2_len := length(sd2_);

  if (sd1_len = 0) or (sd2_len = 0) then
      exit;

  if sd1_len > sd2_len then
    begin
      Swap(sd1_len, sd2_len);
      sd1 := sd2_;
      r1 := r2_;
      sd2 := sd1_;
      r2 := r1_;
    end
  else
    begin
      sd1 := sd1_;
      r1 := r1_;
      sd2 := sd2_;
      r2 := r2_;
    end;

  l := TCoreClassList.Create;
  l.Capacity := sd1_len;

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@Nested_ParallelFor, 0, sd1_len - 1);
{$ELSE FPC}
  TParallel.for(0, sd1_len - 1, procedure(pass: Integer)
    var
      m_idx, j: Integer;
      minf, next_minf: Single;
      d: Single;
      p: PSurfMatched;
    begin
      m_idx := -1;
      minf := MaxRealNumber;
      next_minf := minf;

      // find dsc1 from feat2
      for j := 0 to sd2_len - 1 do
        begin
          d := Min(surf_sqr(@sd1[pass], @sd2[j]), next_minf);
          if (d < minf) then
            begin
              next_minf := minf;
              minf := d;
              m_idx := j;
            end
          else
              next_minf := Min(next_minf, d);
        end;

      // bidirectional rejection
      if (minf > reject_ratio_sqr * next_minf) then
          exit;

      // fix m_idx
      for j := 0 to sd1_len - 1 do
        if j <> pass then
          begin
            d := Min(surf_sqr(@sd1[j], @sd2[m_idx]), next_minf);
            next_minf := Min(next_minf, d);
          end;

      // bidirectional rejection
      if (minf > reject_ratio_sqr * next_minf) then
          exit;

      new(p);
      p^.sd1 := @sd1[pass];
      p^.sd2 := @sd2[m_idx];
      p^.r1 := r1;
      p^.r2 := r2;
      LockObject(l);
      l.Add(p);
      UnLockObject(l);
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor();
{$ENDIF parallel}
  FillMatchInfoAndFreeTemp;
  disposeObject(l);
end;

procedure TAI.BuildFeatureView(Raster: TMemoryRaster; descbuff: TSurf_DescBuffer);
var
  i: Integer;
  p: PSurf_Desc;
begin
  Raster.OpenAgg;
  Raster.Agg.LineWidth := 1.0;
  for i := 0 to length(descbuff) - 1 do
    begin
      p := @descbuff[i];

      Raster.DrawCrossF(p^.x, p^.y, 4, RasterColorF(1, 0, 0, 1));
      Raster.LineF(p^.x, p^.y, p^.dx, p^.dy, RasterColorF(0, 1, 0, 0.5), True);
    end;
end;

function TAI.BuildMatchInfoView(var MatchInfo: TSurfMatchedBuffer): TMemoryRaster;
var
  mr1, mr2: TMemoryRaster;
  c: Byte;
  i, j: Integer;

  p: PSurfMatched;
  RC: TRasterColor;
  v1, v2: TVec2;
begin
  if length(MatchInfo) = 0 then
    begin
      Result := nil;
      exit;
    end;
  Result := NewRaster();

  mr1 := MatchInfo[0].r1;
  mr2 := MatchInfo[0].r2;

  Result.SetSize(mr1.width + mr2.width, Max(mr1.height, mr2.height), RasterColor(0, 0, 0, 0));
  Result.Draw(0, 0, mr1);
  Result.Draw(mr1.width, 0, mr2);
  Result.OpenAgg;

  for i := 0 to length(MatchInfo) - 1 do
    begin
      p := @MatchInfo[i];
      RC := RasterColor(RandomRange(0, 255), RandomRange(0, 255), RandomRange(0, 255), $7F);
      v1 := Geometry2DUnit.Vec2(p^.sd1^.x, p^.sd1^.y);
      v2 := Geometry2DUnit.Vec2(p^.sd2^.x, p^.sd2^.y);
      v2 := Geometry2DUnit.Vec2Add(v2, Geometry2DUnit.Vec2(mr1.width, 0));

      Result.LineF(v1, v2, RC, True);
    end;
end;

function TAI.BuildSurfMatchOutput(raster1, raster2: TMemoryRaster): TMemoryRaster;
var
  r1, r2, output: TMemoryRaster;
  d1, d2: TSurf_DescBuffer;
  matched: TSurfMatchedBuffer;
begin
  r1 := NewRaster();
  r2 := NewRaster();
  r1.Assign(raster1);
  r2.Assign(raster2);
  d1 := fast_surf(r1, 20000, 1.0);
  d2 := fast_surf(r2, 20000, 1.0);
  BuildFeatureView(r1, d1);
  BuildFeatureView(r2, d2);
  matched := Surf_Matched(0.4, r1, r2, d1, d2);
  Result := BuildMatchInfoView(matched);
  disposeObject([r1, r2]);
  SetLength(matched, 0);
  SetLength(d1, 0);
  SetLength(d2, 0);
end;

function TAI.OD_Train(train_cfg, train_output: TPascalString; window_w, window_h, thread_num: Integer): Boolean;
var
  c_train_cfg, c_train_output: C_Bytes;
  train_cfg_buff, train_output_buff: TBytes;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.OD_Train) and (umlFileExists(train_cfg)) and (train_output.Len > 0) then
    begin
      train_cfg_buff := train_cfg.Bytes;
      c_train_cfg.Size := length(train_cfg_buff);
      c_train_cfg.Bytes := @train_cfg_buff[0];

      train_output_buff := train_output.Bytes;
      c_train_output.Size := length(train_output_buff);
      c_train_output.Bytes := @train_output_buff[0];

      try
          Result := AI_Ptr^.OD_Train(@c_train_cfg, @c_train_output, window_w, window_h, thread_num) = 0;
      except
          Result := False;
      end;

      SetLength(train_cfg_buff, 0);
      SetLength(train_output_buff, 0);

      if not Result then
          DoStatus('ZAI: Object Detector Train failed.');
    end
  else
      Result := False;
end;

function TAI.OD_Train(imgList: TAI_ImageList; TokenFilter, train_output: TPascalString; window_w, window_h, thread_num: Integer): Boolean;
var
  ph, fn, Prefix: TPascalString;
  tmpFileList: TPascalStringList;
  i: Integer;
begin
  ph := rootPath;
  tmpFileList := TPascalStringList.Create;

  TCoreClassThread.Sleep(1);
  Prefix := 'temp_OD_' + umlMakeRanName + '_';

  fn := umlCombineFileName(ph, Prefix + 'temp.xml');
  imgList.Build_XML(TokenFilter, False, False, 'ZAI dataset', 'object detector training dataset', fn, Prefix, tmpFileList);

  Result := OD_Train(fn, train_output, window_w, window_h, thread_num);

  for i := 0 to tmpFileList.Count - 1 do
      umlDeleteFile(tmpFileList[i]);

  disposeObject(tmpFileList);
end;

function TAI.OD_Train(imgMat: TAI_ImageMatrix; TokenFilter, train_output: TPascalString; window_w, window_h, thread_num: Integer): Boolean;
var
  ph, fn, Prefix: TPascalString;
  tmpFileList: TPascalStringList;
  i: Integer;
begin
  ph := rootPath;
  tmpFileList := TPascalStringList.Create;

  TCoreClassThread.Sleep(1);
  Prefix := 'temp_OD_' + umlMakeRanName + '_';

  fn := umlCombineFileName(ph, Prefix + 'temp.xml');
  imgMat.Build_XML(TokenFilter, False, False, 'ZAI dataset', 'object detector training dataset', fn, Prefix, tmpFileList);

  Result := OD_Train(fn, train_output, window_w, window_h, thread_num);

  for i := 0 to tmpFileList.Count - 1 do
      umlDeleteFile(tmpFileList[i]);

  disposeObject(tmpFileList);
end;

function TAI.OD_Train_Stream(imgList: TAI_ImageList; window_w, window_h, thread_num: Integer): TMemoryStream64;
var
  fn: TPascalString;
begin
  Result := nil;
  TCoreClassThread.Sleep(1);
  fn := umlCombineFileName(rootPath, PFormat('temp_OD_%s' + zAI.C_OD_Ext, [umlMakeRanName.Text]));

  if OD_Train(imgList, '', fn, window_w, window_h, thread_num) then
    if umlFileExists(fn) then
      begin
        Result := TMemoryStream64.Create;
        Result.LoadFromFile(fn);
        Result.Position := 0;
      end;
  umlDeleteFile(fn);
end;

function TAI.OD_Open(train_file: TPascalString): TOD_Handle;
var
  c_train_file: C_Bytes;
  train_file_buff: TBytes;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.OD_Init) then
    begin
      train_file_buff := train_file.Bytes;
      c_train_file.Size := length(train_file_buff);
      c_train_file.Bytes := @train_file_buff[0];
      Result := AI_Ptr^.OD_Init(@c_train_file);
      if Result <> nil then
          DoStatus('Object detector open: %s', [train_file.Text]);
    end
  else
      Result := nil;
end;

function TAI.OD_Open_Stream(stream: TMemoryStream64): TOD_Handle;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.OD_Init_Memory) then
    begin
      Result := AI_Ptr^.OD_Init_Memory(stream.memory, stream.Size);
      if Result <> nil then
          DoStatus('Object Detector open memory %s size:%s', [umlPointerToStr(stream.memory).Text, umlSizeToStr(stream.Size).Text]);
    end
  else
      Result := nil;
end;

function TAI.OD_Open_Stream(train_file: TPascalString): TOD_Handle;
var
  m64: TMemoryStream64;
begin
  m64 := TMemoryStream64.Create;
  m64.LoadFromFile(train_file);
  Result := OD_Open_Stream(m64);
  disposeObject(m64);
  if Result <> nil then
      DoStatus('Object detector open: %s', [train_file.Text]);
end;

function TAI.OD_Close(var hnd: TOD_Handle): Boolean;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.OD_Free) and (hnd <> nil) then
    begin
      Result := AI_Ptr^.OD_Free(hnd) = 0;
      DoStatus('Object detector Close.', []);
    end
  else
      Result := False;

  hnd := nil;
end;

function TAI.OD_Process(hnd: TOD_Handle; Raster: TMemoryRaster; const max_AI_Rect: Integer): TOD_Desc;
var
  rect_num: Integer;
begin
  SetLength(Result, 0);
  if hnd = nil then
      exit;
  if (AI_Ptr = nil) then
      exit;
  if not Assigned(AI_Ptr^.OD_Process) then
      exit;
  SetLength(Result, max_AI_Rect);

  try
    if AI_Ptr^.OD_Process(hnd, Raster.Bits, Raster.width, Raster.height,
      @Result[0], max_AI_Rect, rect_num) > 0 then
        SetLength(Result, rect_num)
    else
        SetLength(Result, 0);
  except
      SetLength(Result, 0);
  end;
end;

function TAI.OD_Process(hnd: TOD_Handle; Raster: TMemoryRaster): TOD_List;
var
  od_desc: TOD_Desc;
  i: Integer;
begin
  Result := TOD_List.Create;
  od_desc := OD_Process(hnd, Raster, 1024);
  for i := Low(od_desc) to High(od_desc) do
      Result.Add(od_desc[i]);
end;

procedure TAI.OD_Process(hnd: TOD_Handle; Raster: TMemoryRaster; output: TOD_List);
var
  od_desc: TOD_Desc;
  i: Integer;
begin
  od_desc := OD_Process(hnd, Raster, 1024);
  for i := Low(od_desc) to High(od_desc) do
      output.Add(od_desc[i]);
end;

function TAI.OD_Process(hnd: TOD_Handle; rgb_img: TRGB_Image_Handle; const max_AI_Rect: Integer): TOD_Desc;
var
  rect_num: Integer;
begin
  SetLength(Result, 0);
  if hnd = nil then
      exit;
  if (AI_Ptr = nil) then
      exit;
  if not Assigned(AI_Ptr^.OD_Process_Image) then
      exit;
  SetLength(Result, max_AI_Rect);

  try
    if AI_Ptr^.OD_Process_Image(hnd, rgb_img, @Result[0], max_AI_Rect, rect_num) > 0 then
        SetLength(Result, rect_num)
    else
        SetLength(Result, 0);
  except
      SetLength(Result, 0);
  end;
end;

function TAI.OD_Marshal_Train(imgList: TAI_ImageList; window_w, window_h, thread_num: Integer): TMemoryStream64;
var
  dbEng: TObjectDataManager;
  token_arry: TArrayPascalString;
  m64: TMemoryStream64;
  itmHnd: TItemHandle;
  Token: TPascalString;
  fn: TPascalString;
begin
  Result := TMemoryStream64.Create;
  dbEng := TObjectDataManagerOfCache.CreateAsStream(Result, '', DBMarshal.ID, False, True, False);

  imgList.CalibrationNullDetectorDefineToken('null');

  token_arry := imgList.Tokens;
  for Token in token_arry do
    begin
      TCoreClassThread.Sleep(1);
      fn := umlCombineFileName(rootPath, PFormat('temp_OD_%s' + zAI.C_OD_Ext, [umlMakeRanName.Text]));

      if OD_Train(imgList, Token, fn, window_w, window_h, thread_num) then
        begin
          if umlFileExists(fn) then
            begin
              m64 := TMemoryStream64.Create;
              m64.LoadFromFile(fn);
              dbEng.ItemFastCreate(dbEng.RootField, Token, Token, itmHnd);
              dbEng.ItemWrite(itmHnd, m64.Size, m64.memory^);
              dbEng.ItemClose(itmHnd);
              disposeObject(m64);
              umlDeleteFile(fn);
            end;
        end
      else
        begin
          DoStatus('Training "%s" failed.', [Token.Text]);
          disposeObject(dbEng);
          disposeObject(Result);
          Result := nil;
          exit;
        end;
    end;

  disposeObject(dbEng);
end;

function TAI.OD_Marshal_Train(imgMat: TAI_ImageMatrix; window_w, window_h, thread_num: Integer): TMemoryStream64;
var
  i: Integer;
  dbEng: TObjectDataManager;
  token_arry: TArrayPascalString;
  m64: TMemoryStream64;
  itmHnd: TItemHandle;
  Token: TPascalString;
  fn: TPascalString;
begin
  Result := TMemoryStream64.Create;
  dbEng := TObjectDataManagerOfCache.CreateAsStream(Result, '', DBMarshal.ID, False, True, False);

  for i := 0 to imgMat.Count - 1 do
      imgMat[i].CalibrationNullDetectorDefineToken('null');

  token_arry := imgMat.Tokens;
  for Token in token_arry do
    begin
      TCoreClassThread.Sleep(1);
      fn := umlCombineFileName(rootPath, PFormat('temp_OD_%s' + zAI.C_OD_Ext, [umlMakeRanName.Text]));

      if OD_Train(imgMat, Token, fn, window_w, window_h, thread_num) then
        begin
          if umlFileExists(fn) then
            begin
              m64 := TMemoryStream64.Create;
              m64.LoadFromFile(fn);
              dbEng.ItemFastCreate(dbEng.RootField, Token, Token, itmHnd);
              dbEng.ItemWrite(itmHnd, m64.Size, m64.memory^);
              dbEng.ItemClose(itmHnd);
              disposeObject(m64);
              umlDeleteFile(fn);
            end;
        end
      else
        begin
          DoStatus('Training "%s" failed.', [Token.Text]);
          disposeObject(dbEng);
          disposeObject(Result);
          Result := nil;
          exit;
        end;
    end;

  disposeObject(dbEng);
end;

function TAI.OD_Marshal_Open_Stream(stream: TMemoryStream64): TOD_Marshal_Handle;
var
  m64: TMemoryStream64;
  dbEng: TObjectDataManager;
  itmSR: TItemSearch;
  itmHnd: TItemHandle;
  od_hnd: TOD_Handle;
begin
  m64 := TMemoryStream64.Create;
  m64.SetPointerWithProtectedMode(stream.memory, stream.Size);
  dbEng := TObjectDataManagerOfCache.CreateAsStream(m64, '', DBMarshal.ID, True, False, True);

  Result := TOD_Marshal_Handle.Create;
  Result.AutoFreeData := False;

  if dbEng.ItemFastFindFirst(dbEng.RootField, '', itmSR) then
    begin
      repeat
        dbEng.ItemFastOpen(itmSR.HeaderPOS, itmHnd);
        m64 := TMemoryStream64.Create;
        m64.SetSize(itmHnd.Item.Size);
        dbEng.ItemRead(itmHnd, itmHnd.Item.Size, m64.memory^);
        dbEng.ItemClose(itmHnd);

        od_hnd := Result[itmHnd.name];
        if od_hnd <> nil then
            OD_Close(od_hnd);
        od_hnd := OD_Open_Stream(m64);
        Result.Add(itmHnd.name, od_hnd, False);
        disposeObject(m64);

      until not dbEng.ItemFastFindNext(itmSR);
    end;

  disposeObject(dbEng);

  DoStatus('Object Detector marshal open memory %s size:%s', [umlPointerToStr(stream.memory).Text, umlSizeToStr(stream.Size).Text]);
end;

function TAI.OD_Marshal_Open_Stream(train_file: TPascalString): TOD_Marshal_Handle;
var
  m64: TMemoryStream64;
begin
  m64 := TMemoryStream64.Create;
  m64.LoadFromFile(train_file);
  Result := OD_Marshal_Open_Stream(m64);
  disposeObject(m64);
  if Result <> nil then
      DoStatus('Object marshal detector open: %s', [train_file.Text]);
end;

function TAI.OD_Marshal_Close(var hnd: TOD_Marshal_Handle): Boolean;
var
  i: Integer;
  p: PHashListData;
begin
  if hnd.Count > 0 then
    begin
      i := 0;
      p := hnd.FirstPtr;
      while i < hnd.Count do
        begin
          OD_Close(p^.data);
          inc(i);
          p := p^.Next;
        end;
    end;
  disposeObject(hnd);
  Result := True;
end;

function TAI.OD_Marshal_Process(hnd: TOD_Marshal_Handle; Raster: TMemoryRaster): TOD_Marshal_Desc;
var
  lst: TCoreClassList;
  output: TOD_Marshal_List;
  rgb_img: TRGB_Image_Handle;

{$IFDEF parallel}
{$IFDEF FPC}
  procedure FPC_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  var
    j: Integer;
    p: PHashListData;
    od_desc: TOD_Desc;
    omr: TOD_Marshal_Rect;
  begin
    p := PHashListData(lst[pass]);
    od_desc := OD_Process(p^.data, rgb_img, 1024);
    for j := low(od_desc) to high(od_desc) do
      begin
        omr.R := RectV2(od_desc[j]);
        omr.Token := p^.OriginName;
        LockObject(output);
        output.Add(omr);
        UnLockObject(output);
      end;
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure DoFor_;
  var
    pass, j: Integer;
    p: PHashListData;
    od_desc: TOD_Desc;
    omr: TOD_Marshal_Rect;
  begin
    for pass := 0 to lst.Count - 1 do
      begin
        p := PHashListData(lst[pass]);
        od_desc := OD_Process(p^.data, rgb_img, 1024);
        for j := low(od_desc) to high(od_desc) do
          begin
            omr.R := RectV2(od_desc[j]);
            omr.Token := p^.OriginName;
            output.Add(omr);
          end;
      end;
  end;
{$ENDIF parallel}
  procedure FillResult_;
  var
    i: Integer;
  begin
    SetLength(Result, output.Count);
    for i := 0 to output.Count - 1 do
        Result[i] := output[i];
  end;

begin
  output := TOD_Marshal_List.Create;
  lst := TCoreClassList.Create;
  hnd.GetListData(lst);

  rgb_img := AI_Ptr^.Prepare_RGB_Image(Raster.Bits, Raster.width, Raster.height);

{$IFDEF parallel}
{$IFDEF FPC}
  ProcThreadPool.DoParallelLocalProc(@FPC_ParallelFor, 0, lst.Count - 1);
{$ELSE FPC}
  TParallel.for(0, lst.Count - 1, procedure(pass: Integer)
    var
      j: Integer;
      p: PHashListData;
      od_desc: TOD_Desc;
      omr: TOD_Marshal_Rect;
    begin
      p := PHashListData(lst[pass]);
      od_desc := OD_Process(p^.data, rgb_img, 1024);
      for j := low(od_desc) to high(od_desc) do
        begin
          omr.R := RectV2(od_desc[j]);
          omr.Token := p^.OriginName;
          LockObject(output);
          output.Add(omr);
          UnLockObject(output);
        end;
    end);
{$ENDIF FPC}
{$ELSE parallel}
  DoFor_;
{$ENDIF parallel}
  FillResult_;

  AI_Ptr^.Close_RGB_Image(rgb_img);

  disposeObject(output);
  disposeObject(lst);
end;

function TAI.SP_Train(train_cfg, train_output: TPascalString; oversampling_amount, tree_depth, thread_num: Integer): Boolean;
var
  c_train_cfg, c_train_output: C_Bytes;
  train_cfg_buff, train_output_buff: TBytes;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.SP_Train) and (umlFileExists(train_cfg)) and (train_output.Len > 0) then
    begin
      train_cfg_buff := train_cfg.Bytes;
      c_train_cfg.Size := length(train_cfg_buff);
      c_train_cfg.Bytes := @train_cfg_buff[0];

      train_output_buff := train_output.Bytes;
      c_train_output.Size := length(train_output_buff);
      c_train_output.Bytes := @train_output_buff[0];

      try
          Result := AI_Ptr^.SP_Train(@c_train_cfg, @c_train_output, oversampling_amount, tree_depth, thread_num) = 0;
      except
          Result := False;
      end;

      SetLength(train_cfg_buff, 0);
      SetLength(train_output_buff, 0);
      if not Result then
          DoStatus('ZAI: Shape Predictor Train failed.');
    end
  else
      Result := False;
end;

function TAI.SP_Train(imgList: TAI_ImageList; train_output: TPascalString; oversampling_amount, tree_depth, thread_num: Integer): Boolean;
var
  ph, fn, Prefix: TPascalString;
  tmpFileList: TPascalStringList;
  i: Integer;
begin
  ph := rootPath;
  tmpFileList := TPascalStringList.Create;

  TCoreClassThread.Sleep(1);
  Prefix := 'temp_SP_' + umlMakeRanName + '_';

  fn := umlCombineFileName(ph, Prefix + 'temp.xml');
  imgList.Build_XML(True, True, 'ZAI dataset', 'Shape predictor dataset', fn, Prefix, tmpFileList);

  Result := SP_Train(fn, train_output, oversampling_amount, tree_depth, thread_num);

  for i := 0 to tmpFileList.Count - 1 do
      umlDeleteFile(tmpFileList[i]);

  disposeObject(tmpFileList);
end;

function TAI.SP_Train(imgMat: TAI_ImageMatrix; train_output: TPascalString; oversampling_amount, tree_depth, thread_num: Integer): Boolean;
var
  ph, fn, Prefix: TPascalString;
  tmpFileList: TPascalStringList;
  i: Integer;
begin
  ph := rootPath;
  tmpFileList := TPascalStringList.Create;

  TCoreClassThread.Sleep(1);
  Prefix := 'temp_SP_' + umlMakeRanName + '_';

  fn := umlCombineFileName(ph, Prefix + 'temp.xml');
  imgMat.Build_XML(True, True, 'ZAI dataset', 'Shape predictor dataset', fn, Prefix, tmpFileList);

  Result := SP_Train(fn, train_output, oversampling_amount, tree_depth, thread_num);

  for i := 0 to tmpFileList.Count - 1 do
      umlDeleteFile(tmpFileList[i]);

  disposeObject(tmpFileList);
end;

function TAI.SP_Train_Stream(imgList: TAI_ImageList; oversampling_amount, tree_depth, thread_num: Integer): TMemoryStream64;
var
  fn: TPascalString;
begin
  Result := nil;
  TCoreClassThread.Sleep(1);
  fn := umlCombineFileName(rootPath, PFormat('temp_SP_%s' + zAI.C_SP_Ext, [umlMakeRanName.Text]));

  if SP_Train(imgList, fn, oversampling_amount, tree_depth, thread_num) then
    if umlFileExists(fn) then
      begin
        Result := TMemoryStream64.Create;
        Result.LoadFromFile(fn);
        Result.Position := 0;
      end;
  umlDeleteFile(fn);
end;

function TAI.SP_Open(train_file: TPascalString): TSP_Handle;
var
  c_train_file: C_Bytes;
  train_file_buff: TBytes;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.SP_Init) then
    begin
      train_file_buff := train_file.Bytes;
      c_train_file.Size := length(train_file_buff);
      c_train_file.Bytes := @train_file_buff[0];
      Result := AI_Ptr^.SP_Init(@c_train_file);
      if Result <> nil then
          DoStatus('shape predictor open: %s', [train_file.Text]);
    end
  else
      Result := nil;
end;

function TAI.SP_Open_Stream(stream: TMemoryStream64): TSP_Handle;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.SP_Init_Memory) then
    begin
      Result := AI_Ptr^.SP_Init_Memory(stream.memory, stream.Size);
      if Result <> nil then
          DoStatus('shape predictor open memory %s size:%s', [umlPointerToStr(stream.memory).Text, umlSizeToStr(stream.Size).Text]);
    end
  else
      Result := nil;
end;

function TAI.SP_Open_Stream(train_file: TPascalString): TSP_Handle;
var
  m64: TMemoryStream64;
begin
  m64 := TMemoryStream64.Create;
  m64.LoadFromFile(train_file);
  Result := SP_Open_Stream(m64);
  disposeObject(m64);
  if Result <> nil then
      DoStatus('shape predictor open: %s', [train_file.Text]);
end;

function TAI.SP_Close(var hnd: TSP_Handle): Boolean;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.SP_Free) and (hnd <> nil) then
    begin
      Result := AI_Ptr^.SP_Free(hnd) = 0;
      DoStatus('shape predictor close.', []);
    end
  else
      Result := False;

  hnd := nil;
end;

function TAI.SP_Process(hnd: TSP_Handle; Raster: TMemoryRaster; const AI_Rect: TAI_Rect; const max_AI_Point: Integer): TSP_Desc;
var
  point_num: Integer;
begin
  SetLength(Result, 0);
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_Process) then
      exit;
  SetLength(Result, max_AI_Point);

  try
    if AI_Ptr^.SP_Process(hnd, Raster.Bits, Raster.width, Raster.height,
      @AI_Rect, @Result[0], max_AI_Point, point_num) > 0 then
        SetLength(Result, point_num)
    else
        SetLength(Result, 0);
  except
      SetLength(Result, 0);
  end;
end;

function TAI.SP_Process_Vec2List(hnd: TSP_Handle; Raster: TMemoryRaster; const R: TRectV2): TVec2List;
var
  desc: TSP_Desc;
  i: Integer;
begin
  desc := SP_Process(hnd, Raster, AIRect(R), 1024);
  Result := TVec2List.Create;
  for i := 0 to length(desc) - 1 do
      Result.Add(Vec2(desc[i]));
end;

function TAI.SP_Process_Vec2(hnd: TSP_Handle; Raster: TMemoryRaster; const R: TRectV2): TArrayVec2;
var
  desc: TSP_Desc;
  i: Integer;
begin
  desc := SP_Process(hnd, Raster, AIRect(R), 1024);
  SetLength(Result, length(desc));
  for i := 0 to length(desc) - 1 do
      Result[i] := Vec2(desc[i]);
end;

function TAI.SP_Process_Vec2(hnd: TSP_Handle; Raster: TMemoryRaster; const R: TAI_Rect): TArrayVec2;
var
  desc: TSP_Desc;
  i: Integer;
begin
  desc := SP_Process(hnd, Raster, R, 1024);
  SetLength(Result, length(desc));
  for i := 0 to length(desc) - 1 do
      Result[i] := Vec2(desc[i]);
end;

procedure TAI.PrepareFaceDataSource;
var
  m64: TMemoryStream64;
begin
  Wait_AI_Init;
  try
    if (face_sp_hnd = nil) then
      begin
        m64 := TMemoryStream64.Create;
        m64.SetPointerWithProtectedMode(build_in_face_shape_memory, build_in_face_shape_memory_siz);
        m64.Position := 0;
        face_sp_hnd := SP_Open_Stream(m64);
        disposeObject(m64);
      end;
  except
      face_sp_hnd := nil;
  end;
end;

function TAI.Face_Detector(Raster: TMemoryRaster; R: TRect; extract_face_size: Integer): TFACE_Handle;
var
  desc: TOD_Desc;
begin
  SetLength(desc, 1);
  desc[0] := AIRect(R);
  Result := Face_Detector(Raster, desc, extract_face_size);
  SetLength(desc, 0);
end;

function TAI.Face_Detector(Raster: TMemoryRaster; desc: TOD_Desc; extract_face_size: Integer): TFACE_Handle;
var
  i: Integer;
  fixed_desc: TOD_Desc;
begin
  Result := nil;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_extract_face_rect_desc_chips) then
      exit;
  if length(desc) = 0 then
      exit;

  PrepareFaceDataSource;
  SetLength(fixed_desc, length(desc));
  for i := 0 to length(desc) - 1 do
      fixed_desc[i] := AIRect(RectScaleSpace(RectV2(desc[i]), extract_face_size, extract_face_size));

  try
      Result := AI_Ptr^.SP_extract_face_rect_desc_chips(face_sp_hnd, Raster.Bits, Raster.width, Raster.height, extract_face_size, @fixed_desc[0], length(desc));
  except
      Result := nil;
  end;
  SetLength(fixed_desc, 0);
end;

function TAI.Face_Detector(Raster: TMemoryRaster; mmod_desc: TMMOD_Desc; extract_face_size: Integer): TFACE_Handle;
var
  i: Integer;
  od_desc: TOD_Desc;
begin
  SetLength(od_desc, length(mmod_desc));
  for i := 0 to length(mmod_desc) - 1 do
      od_desc[i] := AIRect(mmod_desc[i].R);
  Result := Face_Detector(Raster, od_desc, extract_face_size);
  SetLength(od_desc, 0);
end;

function TAI.Face_DetectorAsChips(Raster: TMemoryRaster; desc: TAI_Rect; extract_face_size: Integer): TMemoryRaster;
var
  face_hnd: TFACE_Handle;
begin
  Result := nil;
  if not Activted then
      exit;
  face_hnd := Face_Detector(Raster, Rect(desc), extract_face_size);
  if face_hnd = nil then
      exit;
  if Face_chips_num(face_hnd) > 0 then
      Result := Face_chips(face_hnd, 0);
  Face_Close(face_hnd);
end;

function TAI.Face_Detector_All(Raster: TMemoryRaster): TFACE_Handle;
begin
  Result := Face_Detector_All(Raster, C_Metric_ResNet_Image_Size);
end;

function TAI.Face_Detector_All(Raster: TMemoryRaster; extract_face_size: Integer): TFACE_Handle;
begin
  Result := nil;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_extract_face_rect_chips) then
      exit;
  PrepareFaceDataSource;
  try
      Result := AI_Ptr^.SP_extract_face_rect_chips(face_sp_hnd, Raster.Bits, Raster.width, Raster.height, extract_face_size);
  except
      Result := nil;
  end;
end;

function TAI.Face_Detector_Rect(Raster: TMemoryRaster): TFACE_Handle;
begin
  Result := nil;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_extract_face_rect) then
      exit;

  try
      Result := AI_Ptr^.SP_extract_face_rect(Raster.Bits, Raster.width, Raster.height);
  except
      Result := nil;
  end;
end;

function TAI.Face_Detector_AllRect(Raster: TMemoryRaster): TOD_Desc;
var
  face_hnd: TFACE_Handle;
  i: Integer;
begin
  SetLength(Result, 0);
  face_hnd := Face_Detector_Rect(Raster);
  if face_hnd = nil then
      exit;
  SetLength(Result, Face_Rect_Num(face_hnd));
  for i := 0 to length(Result) - 1 do
      Result[i] := Face_Rect(face_hnd, i);
  Face_Close(face_hnd);
end;

function TAI.Face_chips_num(hnd: TFACE_Handle): Integer;
begin
  Result := 0;
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_get_face_chips_num) then
      exit;

  Result := AI_Ptr^.SP_get_face_chips_num(hnd);
end;

function TAI.Face_chips(hnd: TFACE_Handle; index: Integer): TMemoryRaster;
var
  w, h: Integer;
begin
  Result := nil;
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_get_face_chips_size) then
      exit;
  if not Assigned(AI_Ptr^.SP_get_face_chips_bits) then
      exit;

  Result := NewRaster();
  AI_Ptr^.SP_get_face_chips_size(hnd, index, w, h);
  Result.SetSize(w, h);
  AI_Ptr^.SP_get_face_chips_bits(hnd, index, Result.Bits);
end;

function TAI.Face_Rect_Num(hnd: TFACE_Handle): Integer;
begin
  Result := 0;
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_get_face_rect_num) then
      exit;

  Result := AI_Ptr^.SP_get_face_rect_num(hnd);
end;

function TAI.Face_Rect(hnd: TFACE_Handle; index: Integer): TAI_Rect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := 0;
  Result.Bottom := 0;
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_get_face_rect) then
      exit;

  AI_Ptr^.SP_get_face_rect(hnd, index, Result);
end;

function TAI.Face_RectV2(hnd: TFACE_Handle; index: Integer): TRectV2;
begin
  Result := RectV2(Face_Rect(hnd, index));
end;

function TAI.Face_Shape_num(hnd: TFACE_Handle): Integer;
begin
  Result := 0;
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_get_num) then
      exit;

  Result := AI_Ptr^.SP_get_num(hnd);
end;

function TAI.Face_Shape(hnd: TFACE_Handle; index: Integer): TSP_Desc;
var
  sp_num: Integer;
begin
  SetLength(Result, 0);
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_get) then
      exit;

  SetLength(Result, 1024);
  sp_num := AI_Ptr^.SP_get(hnd, index, @Result[0], length(Result));
  SetLength(Result, sp_num);
end;

function TAI.Face_ShapeV2(hnd: TFACE_Handle; index: Integer): TArrayVec2;
var
  sp_num: Integer;
  buff: TSP_Desc;
  i: Integer;
begin
  SetLength(Result, 0);
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_get) then
      exit;

  SetLength(buff, 1024);
  sp_num := AI_Ptr^.SP_get(hnd, index, @buff[0], length(buff));
  SetLength(buff, sp_num);
  SetLength(Result, sp_num);
  for i := Low(buff) to high(buff) do
      Result[i] := Vec2(buff[i]);
end;

function TAI.Face_Shape_rect(hnd: TFACE_Handle; index: Integer): TRectV2;
var
  sp_desc: TSP_Desc;
begin
  sp_desc := Face_Shape(hnd, index);
  Result := GetSPBound(sp_desc, 0);
  SetLength(sp_desc, 0);
end;

procedure TAI.Face_Close(var hnd: TFACE_Handle);
begin
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.SP_close_face_chips_handle) then
      exit;

  AI_Ptr^.SP_close_face_chips_handle(hnd);
  hnd := nil;
end;

class function TAI.Init_Metric_ResNet_Parameter(train_sync_file, train_output: TPascalString): PMetric_ResNet_Train_Parameter;
begin
  new(Result);
  FillPtrByte(Result, SizeOf(TMetric_ResNet_Train_Parameter), 0);

  Result^.imgArry_ptr := nil;
  Result^.img_num := 0;
  Result^.train_sync_file := Alloc_P_Bytes(train_sync_file);
  Result^.train_output := Alloc_P_Bytes(train_output);

  Result^.timeout := C_Tick_Hour;
  Result^.weight_decay := 0.0001;
  Result^.momentum := 0.9;
  Result^.iterations_without_progress_threshold := 500;
  Result^.learning_rate := 0.1;
  Result^.completed_learning_rate := 0.0001;
  Result^.step_mini_batch_target_num := 5;
  Result^.step_mini_batch_raster_num := 5;

  Result^.control := nil;
  Result^.training_average_loss := 0;
  Result^.training_learning_rate := 0;

  Result^.fullGPU_Training := True;
end;

class procedure TAI.Free_Metric_ResNet_Parameter(param: PMetric_ResNet_Train_Parameter);
begin
  Free_P_Bytes(param^.train_sync_file);
  Free_P_Bytes(param^.train_output);
  Dispose(param);
end;

function TAI.Metric_ResNet_Train(imgList: TMemoryRaster2DArray; param: PMetric_ResNet_Train_Parameter): Boolean;
var
  i, j, imgSum, ri: Integer;
  imgArry: TMemoryRasterArray;
  rArry: array of TAI_Raster_Data;
begin
  Result := False;

  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.MDNN_ResNet_Train) then
      exit;

  imgSum := 0;
  for i := 0 to length(imgList) - 1 do
      inc(imgSum, length(imgList[i]));

  if imgSum = 0 then
      exit;

  // process sequence
  SetLength(rArry, imgSum);
  ri := 0;
  for i := 0 to length(imgList) - 1 do
    begin
      imgArry := imgList[i];
      for j := 0 to length(imgArry) - 1 do
        begin
          rArry[ri].raster_ptr := imgArry[j].Bits;
          rArry[ri].width := imgArry[j].width;
          rArry[ri].height := imgArry[j].height;
          rArry[ri].index := i;
          inc(ri);
        end;
    end;

  // set arry
  param^.imgArry_ptr := PAI_Raster_Data_Array(@rArry[0]);
  param^.img_num := length(rArry);
  param^.control := @TrainingControl;

  // execute train
  TrainingControl.pause := 0;
  TrainingControl.stop := 0;

  // run train
  if param^.fullGPU_Training then
      Result := AI_Ptr^.MDNN_ResNet_Full_GPU_Train(param) >= 0
  else
      Result := AI_Ptr^.MDNN_ResNet_Train(param) >= 0;

  Last_training_average_loss := param^.training_average_loss;
  Last_training_learning_rate := param^.training_learning_rate;

  // reset arry
  param^.imgArry_ptr := nil;
  param^.img_num := 0;

  // free res
  SetLength(rArry, 0);
end;

function TAI.Metric_ResNet_Train(imgList: TAI_ImageList; param: PMetric_ResNet_Train_Parameter): Boolean;
var
  imgBuff: TMemoryRaster2DArray;
  i, j: Integer;
begin
  Result := False;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.MDNN_ResNet_Train) then
      exit;

  imgBuff := imgList.ExtractDetectorDefineAsPrepareRaster(C_Metric_ResNet_Image_Size, C_Metric_ResNet_Image_Size);

  if length(imgBuff) = 0 then
      exit;

  Result := Metric_ResNet_Train(imgBuff, param);

  for i := 0 to length(imgBuff) - 1 do
    for j := 0 to length(imgBuff[i]) - 1 do
        disposeObject(imgBuff[i, j]);
  SetLength(imgBuff, 0, 0);
end;

function TAI.Metric_ResNet_Train_Stream(imgList: TAI_ImageList; param: PMetric_ResNet_Train_Parameter): TMemoryStream64;
var
  fn: TPascalString;
begin
  Result := nil;

  if Metric_ResNet_Train(imgList, param) then
    begin
      fn := Get_P_Bytes_String(param^.train_output);
      if umlFileExists(fn) then
        begin
          Result := TMemoryStream64.Create;
          Result.LoadFromFile(fn);
          Result.Position := 0;
        end;
    end;
end;

function TAI.Metric_ResNet_Train(imgMat: TAI_ImageMatrix; param: PMetric_ResNet_Train_Parameter): Boolean;
var
  imgBuff: TMemoryRaster2DArray;
  i, j: Integer;
begin
  Result := False;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.MDNN_ResNet_Train) then
      exit;

  imgBuff := imgMat.ExtractDetectorDefineAsPrepareRaster(C_Metric_ResNet_Image_Size, C_Metric_ResNet_Image_Size);

  if length(imgBuff) = 0 then
      exit;

  Result := Metric_ResNet_Train(imgBuff, param);

  for i := 0 to length(imgBuff) - 1 do
    for j := 0 to length(imgBuff[i]) - 1 do
        disposeObject(imgBuff[i, j]);
  SetLength(imgBuff, 0, 0);
end;

function TAI.Metric_ResNet_Train_Stream(imgMat: TAI_ImageMatrix; param: PMetric_ResNet_Train_Parameter): TMemoryStream64;
var
  fn: TPascalString;
begin
  Result := nil;

  if Metric_ResNet_Train(imgMat, param) then
    begin
      fn := Get_P_Bytes_String(param^.train_output);
      if umlFileExists(fn) then
        begin
          Result := TMemoryStream64.Create;
          Result.LoadFromFile(fn);
          Result.Position := 0;
        end;
    end;
end;

function TAI.Metric_ResNet_Open(train_file: TPascalString): TMDNN_Handle;
var
  c_train_file: C_Bytes;
  train_file_buff: TBytes;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.MDNN_ResNet_Init) then
    begin
      train_file_buff := train_file.Bytes;
      c_train_file.Size := length(train_file_buff);
      if c_train_file.Size > 0 then
          c_train_file.Bytes := @train_file_buff[0]
      else
          c_train_file.Bytes := nil;
      Result := AI_Ptr^.MDNN_ResNet_Init(@c_train_file);
      if Result <> nil then
          DoStatus('MDNN-ResNet(ResNet matric DNN) open: %s', [train_file.Text]);
    end
  else
      Result := nil;
end;

function TAI.Metric_ResNet_Open_Stream(stream: TMemoryStream64): TMDNN_Handle;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.MDNN_ResNet_Init_Memory) then
    begin
      Result := AI_Ptr^.MDNN_ResNet_Init_Memory(stream.memory, stream.Size);
      if Result <> nil then
          DoStatus('MDNN-ResNet(ResNet matric DNN) open memory %s size:%s', [umlPointerToStr(stream.memory).Text, umlSizeToStr(stream.Size).Text]);
    end
  else
      Result := nil;
end;

function TAI.Metric_ResNet_Open_Stream(train_file: TPascalString): TMDNN_Handle;
var
  m64: TMemoryStream64;
begin
  m64 := TMemoryStream64.Create;
  m64.LoadFromFile(train_file);
  Result := Metric_ResNet_Open_Stream(m64);
  disposeObject(m64);
  if Result <> nil then
      DoStatus('MDNN-ResNet(ResNet matric DNN) open: %s', [train_file.Text]);
end;

function TAI.Metric_ResNet_Close(var hnd: TMDNN_Handle): Boolean;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.MDNN_ResNet_Free) and (hnd <> nil) then
    begin
      Result := AI_Ptr^.MDNN_ResNet_Free(hnd) = 0;
      DoStatus('MDNN-ResNet(ResNet matric DNN) close.', []);
    end
  else
      Result := False;

  hnd := nil;
end;

function TAI.Metric_ResNet_Process(hnd: TMDNN_Handle; RasterArray: TMemoryRasterArray; output: PDouble): Integer;
var
  rArry: array of TAI_Raster_Data;
  i: Integer;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.MDNN_ResNet_Process) then
    begin
      SetLength(rArry, length(RasterArray));
      for i := 0 to length(RasterArray) - 1 do
        begin
          rArry[i].raster_ptr := RasterArray[i].Bits;
          rArry[i].width := RasterArray[i].width;
          rArry[i].height := RasterArray[i].height;
          rArry[i].index := i;
        end;

      Result := AI_Ptr^.MDNN_ResNet_Process(hnd, PAI_Raster_Data_Array(@rArry[0]), length(rArry), output);
    end
  else
      Result := -2;
end;

function TAI.Metric_ResNet_Process(hnd: TMDNN_Handle; Raster: TMemoryRaster): TLVec;
var
  rArry: TMemoryRasterArray;
begin
  SetLength(Result, C_Metric_ResNet_Dim);
  SetLength(rArry, 1);
  rArry[0] := Raster;
  if Metric_ResNet_Process(hnd, rArry, @Result[0]) <= 0 then
      SetLength(Result, 0);
end;

procedure TAI.Metric_ResNet_SaveDetectorDefineToLearnEngine(mdnn_hnd: TMDNN_Handle; imgList: TAI_ImageList; lr: TLearn);
var
  i, j: Integer;
  imgData: TAI_Image;
  DetDef: TAI_DetectorDefine;
  mr: TMemoryRaster;
  v: TLVec;
begin
  if lr.InLen <> C_Metric_ResNet_Dim then
      RaiseInfo('Learn InLen illegal');
  for i := 0 to imgList.Count - 1 do
    begin
      imgData := imgList[i];
      for j := 0 to imgData.DetectorDefineList.Count - 1 do
        begin
          DetDef := imgData.DetectorDefineList[j];
          if not DetDef.PrepareRaster.Empty then
            begin
              mr := NewRaster();
              mr.ZoomFrom(DetDef.PrepareRaster, C_Metric_ResNet_Image_Size, C_Metric_ResNet_Image_Size);
              v := Metric_ResNet_Process(mdnn_hnd, mr);
              disposeObject(mr);
              if length(v) <> C_Metric_ResNet_Dim then
                  DoStatus('Metric-ResNet vector error!')
              else
                  lr.AddMemory(v, DetDef.Token);
            end;
        end;
    end;
end;

procedure TAI.Metric_ResNet_SaveDetectorDefineToLearnEngine(mdnn_hnd: TMDNN_Handle; imgMat: TAI_ImageMatrix; lr: TLearn);
var
  i: Integer;
begin
  for i := 0 to imgMat.Count - 1 do
      Metric_ResNet_SaveDetectorDefineToLearnEngine(mdnn_hnd, imgMat[i], lr);
end;

function TAI.Metric_ResNet_DebugInfo(hnd: TMDNN_Handle): TPascalString;
var
  p: PPascalString;
begin
  Result := '';
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.MDNN_DebugInfo) and (hnd <> nil) then
    begin
      AI_Ptr^.MDNN_DebugInfo(hnd, p);
      Result := p^;
      Dispose(p);
    end;
end;

class function TAI.Init_MMOD_DNN_TrainParam(train_cfg, train_sync_file, train_output: TPascalString): PMMOD_Train_Parameter;
begin
  new(Result);
  FillPtrByte(Result, SizeOf(TMMOD_Train_Parameter), 0);

  Result^.train_cfg := Alloc_P_Bytes(train_cfg);
  Result^.train_sync_file := Alloc_P_Bytes(train_sync_file);
  Result^.train_output := Alloc_P_Bytes(train_output);

  Result^.timeout := C_Tick_Hour;
  Result^.target_size := 100;
  Result^.min_target_size := 20;
  Result^.min_detector_window_overlap_iou := 0.75;
  Result^.iterations_without_progress_threshold := 500;
  Result^.learning_rate := 0.1;
  Result^.completed_learning_rate := 0.0001;
  Result^.num_crops := 10;
  Result^.chip_dims_x := 150;
  Result^.chip_dims_y := 150;
  Result^.min_object_size_x := 95;
  Result^.min_object_size_y := 19;
  Result^.max_rotation_degrees := 50.0;
  Result^.max_object_size := 0.7;

  Result^.control := nil;
  Result^.training_average_loss := 0;
  Result^.training_learning_rate := 0;

  // internal
  Result^.TempFiles := nil;
end;

class procedure TAI.Free_MMOD_DNN_TrainParam(param: PMMOD_Train_Parameter);
begin
  Free_P_Bytes(param^.train_cfg);
  Free_P_Bytes(param^.train_sync_file);
  Free_P_Bytes(param^.train_output);
  Dispose(param);
end;

function TAI.MMOD_DNN_PrepareTrain(imgList: TAI_ImageList; train_sync_file: TPascalString): PMMOD_Train_Parameter;
var
  ph, fn, Prefix, train_out: TPascalString;
  tmpFileList: TPascalStringList;
begin
  ph := rootPath;
  tmpFileList := TPascalStringList.Create;
  TCoreClassThread.Sleep(1);
  Prefix := 'MMOD_DNN_' + umlMakeRanName + '_';
  fn := umlCombineFileName(ph, Prefix + 'temp.xml');
  imgList.Build_XML(True, False, 'ZAI dataset', 'dnn resnet max-margin dataset', fn, Prefix, tmpFileList);
  train_out := Prefix + 'output' + zAI.C_MMOD_Ext;
  Result := Init_MMOD_DNN_TrainParam(fn, train_sync_file, train_out);
  Result^.control := @TrainingControl;
  Result^.TempFiles := tmpFileList;
end;

function TAI.MMOD_DNN_PrepareTrain(imgMat: TAI_ImageMatrix; train_sync_file: TPascalString): PMMOD_Train_Parameter;
var
  ph, fn, Prefix, train_out: TPascalString;
  tmpFileList: TPascalStringList;
begin
  ph := rootPath;
  tmpFileList := TPascalStringList.Create;
  TCoreClassThread.Sleep(1);
  Prefix := 'MMOD_DNN_' + umlMakeRanName + '_';
  fn := umlCombineFileName(ph, Prefix + 'temp.xml');
  imgMat.Build_XML(True, False, 'ZAI dataset', 'build-in', fn, Prefix, tmpFileList);
  train_out := Prefix + 'output' + zAI.C_MMOD_Ext;
  Result := Init_MMOD_DNN_TrainParam(fn, train_sync_file, train_out);
  Result^.control := @TrainingControl;
  Result^.TempFiles := tmpFileList;
end;

function TAI.MMOD_DNN_Train(param: PMMOD_Train_Parameter): Integer;
begin
  Result := -1;
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.MMOD_DNN_Train) then
    begin
      TrainingControl.pause := 0;
      TrainingControl.stop := 0;
      Result := AI_Ptr^.MMOD_DNN_Train(param);
      Last_training_average_loss := param^.training_average_loss;
      Last_training_learning_rate := param^.training_learning_rate;
      if Result > 0 then
          param^.TempFiles.Add(Get_P_Bytes_String(param^.train_output));
    end;
end;

function TAI.MMOD_DNN_Train_Stream(param: PMMOD_Train_Parameter): TMemoryStream64;
var
  fn: TPascalString;
begin
  Result := nil;
  fn := Get_P_Bytes_String(param^.train_output);
  if (MMOD_DNN_Train(param) > 0) and (umlFileExists(fn)) then
    begin
      Result := TMemoryStream64.Create;
      Result.LoadFromFile(fn);
      Result.Position := 0;
    end;
end;

procedure TAI.MMOD_DNN_FreeTrain(param: PMMOD_Train_Parameter);
var
  i: Integer;
begin
  for i := 0 to param^.TempFiles.Count - 1 do
      umlDeleteFile(param^.TempFiles[i]);
  disposeObject(param^.TempFiles);
  param^.TempFiles := nil;

  Free_MMOD_DNN_TrainParam(param);
end;

function TAI.MMOD_DNN_Open(train_file: TPascalString): TMMOD_Handle;
var
  c_train_file: C_Bytes;
  train_file_buff: TBytes;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.MMOD_DNN_Init) then
    begin
      train_file_buff := train_file.Bytes;
      c_train_file.Size := length(train_file_buff);
      c_train_file.Bytes := @train_file_buff[0];
      Result := AI_Ptr^.MMOD_DNN_Init(@c_train_file);
      if Result <> nil then
          DoStatus('MMOD-DNN(DNN+SVM:max-margin object detector) open: %s', [train_file.Text]);
    end
  else
      Result := nil;
end;

function TAI.MMOD_DNN_Open_Stream(stream: TMemoryStream64): TMMOD_Handle;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.MMOD_DNN_Init_Memory) then
    begin
      Result := AI_Ptr^.MMOD_DNN_Init_Memory(stream.memory, stream.Size);
      if Result <> nil then
          DoStatus('MMOD-DNN(DNN+SVM:max-margin object detector) open memory %s size:%s', [umlPointerToStr(stream.memory).Text, umlSizeToStr(stream.Size).Text]);
    end
  else
      Result := nil;
end;

function TAI.MMOD_DNN_Open_Stream(train_file: TPascalString): TMMOD_Handle;
var
  m64: TMemoryStream64;
begin
  m64 := TMemoryStream64.Create;
  m64.LoadFromFile(train_file);
  Result := MMOD_DNN_Open_Stream(m64);
  disposeObject(m64);
  if Result <> nil then
      DoStatus('MMOD-DNN(DNN+SVM:max-margin object detector) open: %s', [train_file.Text]);
end;

function TAI.MMOD_DNN_Close(var hnd: TMMOD_Handle): Boolean;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.MMOD_DNN_Free) and (hnd <> nil) then
    begin
      Result := AI_Ptr^.MMOD_DNN_Free(hnd) = 0;
      DoStatus('MMOD-DNN(DNN+SVM:max-margin object detector) close.', []);
    end
  else
      Result := False;

  hnd := nil;
end;

function TAI.MMOD_DNN_Process(hnd: TMMOD_Handle; Raster: TMemoryRaster): TMMOD_Desc;
var
  rect_num: Integer;
  buff: TAI_MMOD_Desc;
  i: Integer;
begin
  SetLength(Result, 0);
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.MMOD_DNN_Process) then
      exit;
  SetLength(buff, 1024);

  rect_num := AI_Ptr^.MMOD_DNN_Process(hnd, Raster.Bits, Raster.width, Raster.height, @buff[0], 1024);
  if rect_num >= 0 then
    begin
      SetLength(Result, rect_num);
      for i := 0 to rect_num - 1 do
        begin
          Result[i].R := RectV2(buff[i]);
          Result[i].Token := buff[i].Token^;
          AI_FreeString(buff[i].Token);
        end;
    end;
  SetLength(buff, 0);
end;

function TAI.MMOD_DNN_Process_Matrix(hnd: TMMOD_Handle; matrix_img: TMatrix_Image_Handle): TMMOD_Desc;
var
  rect_num: Integer;
  buff: TAI_MMOD_Desc;
  i: Integer;
begin
  SetLength(Result, 0);
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.MMOD_DNN_Process) then
      exit;
  SetLength(buff, 1024);

  rect_num := AI_Ptr^.MMOD_DNN_Process_Image(hnd, matrix_img, @buff[0], 1024);
  if rect_num >= 0 then
    begin
      SetLength(Result, rect_num);
      for i := 0 to rect_num - 1 do
        begin
          Result[i].R := RectV2(buff[i]);
          Result[i].Token := buff[i].Token^;
          AI_FreeString(buff[i].Token);
        end;
    end;
  SetLength(buff, 0);
end;

function TAI.MMOD_DNN_DebugInfo(hnd: TMMOD_Handle): TPascalString;
var
  p: PPascalString;
begin
  Result := '';
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.MMOD_DebugInfo) and (hnd <> nil) then
    begin
      AI_Ptr^.MMOD_DebugInfo(hnd, p);
      Result := p^;
      Dispose(p);
    end;
end;

class function TAI.Init_RNIC_Train_Parameter(train_sync_file, train_output: TPascalString): PRNIC_Train_Parameter;
begin
  new(Result);
  FillPtrByte(Result, SizeOf(TRNIC_Train_Parameter), 0);

  Result^.imgArry_ptr := nil;
  Result^.img_num := 0;
  Result^.train_sync_file := Alloc_P_Bytes(train_sync_file);
  Result^.train_output := Alloc_P_Bytes(train_output);

  Result^.timeout := C_Tick_Hour;
  Result^.weight_decay := 0.0001;
  Result^.momentum := 0.9;
  Result^.iterations_without_progress_threshold := 500;
  Result^.learning_rate := 0.1;
  Result^.completed_learning_rate := 0.0001;
  Result^.all_bn_running_stats_window_sizes := 1000;
  Result^.img_mini_batch := 10;

  Result^.control := nil;
  Result^.training_average_loss := 0;
  Result^.training_learning_rate := 0;
end;

class procedure TAI.Free_RNIC_Train_Parameter(param: PRNIC_Train_Parameter);
begin
  Free_P_Bytes(param^.train_sync_file);
  Free_P_Bytes(param^.train_output);
  Dispose(param);
end;

function TAI.RNIC_Train(imgList: TMemoryRaster2DArray; param: PRNIC_Train_Parameter; Train_OutputIndex: TMemoryRasterList): Boolean;
var
  i, j, imgSum, ri: Integer;
  imgArry: TMemoryRasterArray;
  imgInfo_arry: array of TAI_Raster_Data;
begin
  Result := False;

  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.RNIC_Train) then
      exit;

  imgSum := 0;
  for i := 0 to length(imgList) - 1 do
      inc(imgSum, length(imgList[i]));

  if Train_OutputIndex <> nil then
      Train_OutputIndex.Clear;
  SetLength(imgInfo_arry, imgSum);
  ri := 0;

  for i := 0 to length(imgList) - 1 do
    begin
      imgArry := imgList[i];
      for j := 0 to length(imgArry) - 1 do
        begin
          imgInfo_arry[ri].raster_ptr := imgArry[j].Bits;
          imgInfo_arry[ri].width := imgArry[j].width;
          imgInfo_arry[ri].height := imgArry[j].height;
          imgInfo_arry[ri].index := i;
          imgArry[j].UserVariant := i;

          if Train_OutputIndex <> nil then
              Train_OutputIndex.Add(imgArry[j]);
          inc(ri);
        end;
    end;

  TrainingControl.pause := 0;
  TrainingControl.stop := 0;

  param^.imgArry_ptr := @imgInfo_arry[0];
  param^.img_num := length(imgInfo_arry);
  param^.control := @TrainingControl;

  Result := AI_Ptr^.RNIC_Train(param) > 0;

  Last_training_average_loss := param^.training_average_loss;
  Last_training_learning_rate := param^.training_learning_rate;

  param^.imgArry_ptr := nil;
  param^.img_num := 0;
  param^.control := nil;

  SetLength(imgInfo_arry, 0);
end;

function TAI.RNIC_Train(imgList: TAI_ImageList; param: PRNIC_Train_Parameter; Train_OutputIndex: TPascalStringList): Boolean;
var
  imgBuff: TMemoryRaster2DArray;
  i, j: Integer;
  out_index: TMemoryRasterList;
begin
  Result := False;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.RNIC_Train) then
      exit;

  Train_OutputIndex.Clear;
  imgBuff := imgList.ExtractDetectorDefineAsSnapshot();
  out_index := TMemoryRasterList.Create;
  Result := RNIC_Train(imgBuff, param, out_index);
  if Result then
    for i := 0 to out_index.Count - 1 do
      if Train_OutputIndex.ExistsValue(out_index[i].UserToken) < 0 then
          Train_OutputIndex.Add(out_index[i].UserToken);
  disposeObject(out_index);

  for i := 0 to length(imgBuff) - 1 do
    for j := 0 to length(imgBuff[i]) - 1 do
        disposeObject(imgBuff[i, j]);
  SetLength(imgBuff, 0, 0);
end;

function TAI.RNIC_Train(imgList: TAI_ImageList; param: PRNIC_Train_Parameter; train_index_output: TPascalString): Boolean;
var
  TrainIndex: TPascalStringList;
begin
  TrainIndex := TPascalStringList.Create;
  Result := RNIC_Train(imgList, param, TrainIndex);
  if Result then
      TrainIndex.SaveToFile(train_index_output);
  disposeObject(TrainIndex);
end;

function TAI.RNIC_Train_Stream(imgList: TAI_ImageList; param: PRNIC_Train_Parameter; Train_OutputIndex: TPascalStringList): TMemoryStream64;
var
  fn: TPascalString;
begin
  Result := nil;

  if RNIC_Train(imgList, param, Train_OutputIndex) then
    begin
      fn := Get_P_Bytes_String(param^.train_output);
      if umlFileExists(fn) then
        begin
          Result := TMemoryStream64.Create;
          Result.LoadFromFile(fn);
          Result.Position := 0;
        end;
    end;
end;

function TAI.RNIC_Train(imgMat: TAI_ImageMatrix; param: PRNIC_Train_Parameter; Train_OutputIndex: TPascalStringList): Boolean;
var
  imgBuff: TMemoryRaster2DArray;
  i, j: Integer;
  out_index: TMemoryRasterList;
begin
  Result := False;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.RNIC_Train) then
      exit;

  Train_OutputIndex.Clear;
  imgBuff := imgMat.ExtractDetectorDefineAsSnapshot();
  out_index := TMemoryRasterList.Create;
  Result := RNIC_Train(imgBuff, param, out_index);
  if Result then
    for i := 0 to out_index.Count - 1 do
      if Train_OutputIndex.ExistsValue(out_index[i].UserToken) < 0 then
          Train_OutputIndex.Add(out_index[i].UserToken);
  disposeObject(out_index);

  for i := 0 to length(imgBuff) - 1 do
    for j := 0 to length(imgBuff[i]) - 1 do
        disposeObject(imgBuff[i, j]);
  SetLength(imgBuff, 0, 0);
end;

function TAI.RNIC_Train(imgMat: TAI_ImageMatrix; param: PRNIC_Train_Parameter; train_index_output: TPascalString): Boolean;
var
  TrainIndex: TPascalStringList;
begin
  TrainIndex := TPascalStringList.Create;
  Result := RNIC_Train(imgMat, param, TrainIndex);
  if Result then
      TrainIndex.SaveToFile(train_index_output);
  disposeObject(TrainIndex);
end;

function TAI.RNIC_Train_Stream(imgMat: TAI_ImageMatrix; param: PRNIC_Train_Parameter; Train_OutputIndex: TPascalStringList): TMemoryStream64;
var
  fn: TPascalString;
begin
  Result := nil;

  if RNIC_Train(imgMat, param, Train_OutputIndex) then
    begin
      fn := Get_P_Bytes_String(param^.train_output);
      if umlFileExists(fn) then
        begin
          Result := TMemoryStream64.Create;
          Result.LoadFromFile(fn);
          Result.Position := 0;
        end;
    end;
end;

function TAI.RNIC_Open(train_file: TPascalString): TRNIC_Handle;
var
  c_train_file: C_Bytes;
  train_file_buff: TBytes;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.RNIC_Init) then
    begin
      train_file_buff := train_file.Bytes;
      c_train_file.Size := length(train_file_buff);
      c_train_file.Bytes := @train_file_buff[0];
      Result := AI_Ptr^.RNIC_Init(@c_train_file);
      if Result <> nil then
          DoStatus('ResNet-Image-Classifier open: %s', [train_file.Text]);
    end
  else
      Result := nil;
end;

function TAI.RNIC_Open_Stream(stream: TMemoryStream64): TRNIC_Handle;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.RNIC_Init_Memory) then
    begin
      Result := AI_Ptr^.RNIC_Init_Memory(stream.memory, stream.Size);
      DoStatus('ResNet-Image-Classifier open memory %s size:%s', [umlPointerToStr(stream.memory).Text, umlSizeToStr(stream.Size).Text]);
    end
  else
      Result := nil;
end;

function TAI.RNIC_Open_Stream(train_file: TPascalString): TRNIC_Handle;
var
  m64: TMemoryStream64;
begin
  m64 := TMemoryStream64.Create;
  m64.LoadFromFile(train_file);
  Result := RNIC_Open_Stream(m64);
  disposeObject(m64);
  if Result <> nil then
      DoStatus('ResNet-Image-Classifier open: %s', [train_file.Text]);
end;

function TAI.RNIC_Close(var hnd: TRNIC_Handle): Boolean;
begin
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.RNIC_Free) and (hnd <> nil) then
    begin
      Result := AI_Ptr^.RNIC_Free(hnd) = 0;
      DoStatus('ResNet-Image-Classifier close.', []);
    end
  else
      Result := False;

  hnd := nil;
end;

function TAI.RNIC_Process(hnd: TRNIC_Handle; Raster: TMemoryRaster): TLVec;
var
  R: Integer;
begin
  SetLength(Result, 0);
  if hnd = nil then
      exit;
  if AI_Ptr = nil then
      exit;
  if not Assigned(AI_Ptr^.RNIC_Process) then
      exit;
  SetLength(Result, C_ResNet_Image_Classifier_Dim);
  R := AI_Ptr^.RNIC_Process(hnd, Raster.Bits, Raster.width, Raster.height, @Result[0]);
  if R <> C_ResNet_Image_Classifier_Dim then
      SetLength(Result, 0);
end;

function TAI.RNIC_DebugInfo(hnd: TRNIC_Handle): TPascalString;
var
  p: PPascalString;
begin
  Result := '';
  if (AI_Ptr <> nil) and Assigned(AI_Ptr^.RNIC_DebugInfo) and (hnd <> nil) then
    begin
      AI_Ptr^.RNIC_DebugInfo(hnd, p);
      Result := p^;
      Dispose(p);
    end;
end;

function TAI.Tracker_Open(Raster: TMemoryRaster; track_rect: TRect): TTracker_Handle;
var
  rgb_hnd: TRGB_Image_Handle;
  a: TAI_Rect;
begin
  Result := nil;
  if (AI_Ptr = nil) then
      exit;
  if not Assigned(AI_Ptr^.Start_Tracker) then
      exit;
  rgb_hnd := Prepare_RGB_Image(Raster);
  if rgb_hnd = nil then
      exit;
  a := AIRect(track_rect);
  Result := AI_Ptr^.Start_Tracker(rgb_hnd, @a);
  Close_RGB_Image(rgb_hnd);
end;

function TAI.Tracker_OpenV2(Raster: TMemoryRaster; track_rect: TRectV2): TTracker_Handle;
var
  rgb_hnd: TRGB_Image_Handle;
  a: TAI_Rect;
begin
  Result := nil;
  if (AI_Ptr = nil) then
      exit;
  if not Assigned(AI_Ptr^.Start_Tracker) then
      exit;
  rgb_hnd := Prepare_RGB_Image(Raster);
  if rgb_hnd = nil then
      exit;
  a := AIRect(track_rect);
  Result := AI_Ptr^.Start_Tracker(rgb_hnd, @a);
  Close_RGB_Image(rgb_hnd);
end;

function TAI.Tracker_Update(hnd: TTracker_Handle; Raster: TMemoryRaster; var track_rect: TRect): Double;
var
  rgb_hnd: TRGB_Image_Handle;
  a: TAI_Rect;
begin
  Result := 0;
  if (AI_Ptr = nil) then
      exit;
  if not Assigned(AI_Ptr^.Update_Tracker) then
      exit;

  rgb_hnd := Prepare_RGB_Image(Raster);
  if rgb_hnd = nil then
      exit;
  Result := AI_Ptr^.Update_Tracker(hnd, rgb_hnd, a);
  track_rect := Rect(a);
  Close_RGB_Image(rgb_hnd);
end;

function TAI.Tracker_UpdateV2(hnd: TTracker_Handle; Raster: TMemoryRaster; var track_rect: TRectV2): Double;
var
  rgb_hnd: TRGB_Image_Handle;
  a: TAI_Rect;
begin
  Result := 0;
  if (AI_Ptr = nil) then
      exit;
  if not Assigned(AI_Ptr^.Update_Tracker) then
      exit;

  rgb_hnd := Prepare_RGB_Image(Raster);
  if rgb_hnd = nil then
      exit;
  Result := AI_Ptr^.Update_Tracker(hnd, rgb_hnd, a);
  track_rect := RectV2(a);
  Close_RGB_Image(rgb_hnd);
end;

function TAI.Tracker_Close(var hnd: TTracker_Handle): Boolean;
begin
  Result := False;
  if (AI_Ptr = nil) then
      exit;
  if not Assigned(AI_Ptr^.Stop_Tracker) then
      exit;

  AI_Ptr^.Stop_Tracker(hnd);
  hnd := nil;
  Result := True;
end;

function TAI.Activted: Boolean;
begin
  Result := AI_Ptr <> nil;
end;

constructor TAI_Parallel.Create;
begin
  inherited Create;
  Critical := TSoftCritical.Create;
  Wait_AI_Init;
end;

destructor TAI_Parallel.Destroy;
begin
  Clear;
  disposeObject(Critical);
  inherited Destroy;
end;

procedure TAI_Parallel.Clear;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
      disposeObject(Items[i]);
  inherited Clear;
end;

procedure TAI_Parallel.Delete(index: Integer);
begin
  disposeObject(Items[index]);
  inherited Delete(index);
end;

procedure TAI_Parallel.Prepare_Parallel(lib_p: Pointer; poolSiz: Integer);
var
  i: Integer;
  AI: TAI;
begin
  if lib_p = nil then
      RaiseInfo('engine library failed!');
  Critical.Acquire;
  try
    if poolSiz > Count then
      begin
        for i := Count to poolSiz - 1 do
          begin
            AI := TAI.OpenEngine(lib_p);
            Add(AI);
          end;
      end;
  finally
      Critical.Release;
  end;
end;

procedure TAI_Parallel.Prepare_Parallel(eng: SystemString; poolSiz: Integer);
begin
  Prepare_Parallel(Prepare_AI_Engine(eng), poolSiz);
end;

procedure TAI_Parallel.Prepare_Parallel;
begin
  Prepare_Parallel(zAI_Common.AI_Engine_Library, zAI_Common.AI_Parallel_Count);
end;

procedure TAI_Parallel.Prepare_Face;
{$IFDEF parallel}
{$IFDEF FPC}
  procedure Do_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  begin
    Items[pass].PrepareFaceDataSource;
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure Do_For;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
        Items[pass].PrepareFaceDataSource;
  end;
{$ENDIF parallel}


begin
  Critical.Acquire;
  try
{$IFDEF parallel}
{$IFDEF FPC}
    ProcThreadPool.DoParallelLocalProc(@Do_ParallelFor, 0, Count - 1);
{$ELSE FPC}
    TParallel.for(0, Count - 1, procedure(pass: Integer)
      begin
        Items[pass].PrepareFaceDataSource;
      end);
{$ENDIF FPC}
{$ELSE parallel}
    Do_For;
{$ENDIF parallel}
  finally
      Critical.Release;
  end;
end;

procedure TAI_Parallel.Prepare_OD(stream: TMemoryStream64);
{$IFDEF parallel}
{$IFDEF FPC}
  procedure Do_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  begin
    with Items[pass] do
        Parallel_OD_Hnd := OD_Open_Stream(stream);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure Do_For;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
      with Items[pass] do
          Parallel_OD_Hnd := OD_Open_Stream(stream);
  end;
{$ENDIF parallel}


begin
  Critical.Acquire;
  try
{$IFDEF parallel}
{$IFDEF FPC}
    ProcThreadPool.DoParallelLocalProc(@Do_ParallelFor, 0, Count - 1);
{$ELSE FPC}
    TParallel.for(0, Count - 1, procedure(pass: Integer)
      begin
        with Items[pass] do
            Parallel_OD_Hnd := OD_Open_Stream(stream);
      end);
{$ENDIF FPC}
{$ELSE parallel}
    Do_For;
{$ENDIF parallel}
  finally
      Critical.Release;
  end;
end;

procedure TAI_Parallel.Prepare_OD_Marshal(stream: TMemoryStream64);
{$IFDEF parallel}
{$IFDEF FPC}
  procedure Do_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  begin
    with Items[pass] do
        Parallel_OD_Marshal_Hnd := OD_Marshal_Open_Stream(stream);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure Do_For;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
      with Items[pass] do
          Parallel_OD_Marshal_Hnd := OD_Marshal_Open_Stream(stream);
  end;
{$ENDIF parallel}


begin
  Critical.Acquire;
  try
{$IFDEF parallel}
{$IFDEF FPC}
    ProcThreadPool.DoParallelLocalProc(@Do_ParallelFor, 0, Count - 1);
{$ELSE FPC}
    TParallel.for(0, Count - 1, procedure(pass: Integer)
      begin
        with Items[pass] do
            Parallel_OD_Marshal_Hnd := OD_Marshal_Open_Stream(stream);
      end);
{$ENDIF FPC}
{$ELSE parallel}
    Do_For;
{$ENDIF parallel}
  finally
      Critical.Release;
  end;
end;

procedure TAI_Parallel.Prepare_SP(stream: TMemoryStream64);
{$IFDEF parallel}
{$IFDEF FPC}
  procedure Do_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  begin
    with Items[pass] do
        Parallel_SP_Hnd := SP_Open_Stream(stream);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure Do_For;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
      with Items[pass] do
          Parallel_SP_Hnd := SP_Open_Stream(stream);
  end;
{$ENDIF parallel}


begin
  Critical.Acquire;
  try
{$IFDEF parallel}
{$IFDEF FPC}
    ProcThreadPool.DoParallelLocalProc(@Do_ParallelFor, 0, Count - 1);
{$ELSE FPC}
    TParallel.for(0, Count - 1, procedure(pass: Integer)
      begin
        with Items[pass] do
            Parallel_SP_Hnd := SP_Open_Stream(stream);
      end);
{$ENDIF FPC}
{$ELSE parallel}
    Do_For;
{$ENDIF parallel}
  finally
      Critical.Release;
  end;
end;

procedure TAI_Parallel.Prepare_MDNN(stream: TMemoryStream64);
{$IFDEF parallel}
{$IFDEF FPC}
  procedure Do_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  begin
    with Items[pass] do
        Parallel_MDNN_Hnd := Metric_ResNet_Open_Stream(stream);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure Do_For;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
      with Items[pass] do
          Parallel_MDNN_Hnd := Metric_ResNet_Open_Stream(stream);
  end;
{$ENDIF parallel}


begin
  Critical.Acquire;
  try
{$IFDEF parallel}
{$IFDEF FPC}
    ProcThreadPool.DoParallelLocalProc(@Do_ParallelFor, 0, Count - 1);
{$ELSE FPC}
    TParallel.for(0, Count - 1, procedure(pass: Integer)
      begin
        with Items[pass] do
            Parallel_MDNN_Hnd := Metric_ResNet_Open_Stream(stream);
      end);
{$ENDIF FPC}
{$ELSE parallel}
    Do_For;
{$ENDIF parallel}
  finally
      Critical.Release;
  end;
end;

procedure TAI_Parallel.Prepare_MMOD(stream: TMemoryStream64);
{$IFDEF parallel}
{$IFDEF FPC}
  procedure Do_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  begin
    with Items[pass] do
        Parallel_MMOD_Hnd := MMOD_DNN_Open_Stream(stream);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure Do_For;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
      with Items[pass] do
          Parallel_MMOD_Hnd := MMOD_DNN_Open_Stream(stream);
  end;
{$ENDIF parallel}


begin
  Critical.Acquire;
  try
{$IFDEF parallel}
{$IFDEF FPC}
    ProcThreadPool.DoParallelLocalProc(@Do_ParallelFor, 0, Count - 1);
{$ELSE FPC}
    TParallel.for(0, Count - 1, procedure(pass: Integer)
      begin
        with Items[pass] do
            Parallel_MMOD_Hnd := MMOD_DNN_Open_Stream(stream);
      end);
{$ENDIF FPC}
{$ELSE parallel}
    Do_For;
{$ENDIF parallel}
  finally
      Critical.Release;
  end;
end;

procedure TAI_Parallel.Prepare_RNIC(stream: TMemoryStream64);
{$IFDEF parallel}
{$IFDEF FPC}
  procedure Do_ParallelFor(pass: PtrInt; data: Pointer; Item: TMultiThreadProcItem);
  begin
    with Items[pass] do
        Parallel_RNIC_Hnd := RNIC_Open_Stream(stream);
  end;
{$ENDIF FPC}
{$ELSE parallel}
  procedure Do_For;
  var
    pass: Integer;
  begin
    for pass := 0 to Count - 1 do
      with Items[pass] do
          Parallel_RNIC_Hnd := RNIC_Open_Stream(stream);
  end;
{$ENDIF parallel}


begin
  Critical.Acquire;
  try
{$IFDEF parallel}
{$IFDEF FPC}
    ProcThreadPool.DoParallelLocalProc(@Do_ParallelFor, 0, Count - 1);
{$ELSE FPC}
    TParallel.for(0, Count - 1, procedure(pass: Integer)
      begin
        with Items[pass] do
            Parallel_RNIC_Hnd := RNIC_Open_Stream(stream);
      end);
{$ENDIF FPC}
{$ELSE parallel}
    Do_For;
{$ENDIF parallel}
  finally
      Critical.Release;
  end;
end;

function TAI_Parallel.GetAndLockAI: TAI;
var
  i: Integer;
begin
  Critical.Acquire;
  Result := nil;
  while Result = nil do
    begin
      i := 0;
      while i < Count do
        begin
          if not Items[i].Critical.Busy then
            begin
              Result := Items[i];
              Result.Lock;
              break;
            end;
          inc(i);
        end;
    end;
  Critical.Release;
end;

procedure TAI_Parallel.UnLockAI(AI: TAI);
begin
  AI.Unlock;
end;

initialization

Init_AI_BuildIn;

finalization

Free_AI_BuildIn;

end.
