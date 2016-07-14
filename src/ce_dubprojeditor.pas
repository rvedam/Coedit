unit ce_dubprojeditor;

{$I ce_defines.inc}

interface

uses
  Classes, SysUtils, FileUtil, TreeFilterEdit, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, Menus, StdCtrls, Buttons, ComCtrls, xjsonparser, xfpjson,
  ce_widget, ce_common, ce_interfaces, ce_observer, ce_dubproject, ce_sharedres;

type

  TProposalType = (ptArray, ptObject, ptValue);

  TEditorProposal = record
    name: string;
    jtype: TProposalType;
  end;


  TDubPropAddEvent = procedure(const propName: string; tpe: TJSONtype) of object;

  TCEDubProjectPropAddPanel = class(TForm)
  private
    fSelType: TRadioGroup;
    fEdName: TComboBox;
    fEvent: TDubPropAddEvent;
    fBtnValidate: TBitBtn;
    fJson: TJSONData;
    procedure doValidate(sender: TObject);
    procedure selTypeChanged(sender: TObject);
    procedure setSelFromProposal(sender: TObject);
  public
    constructor construct(event: TDubPropAddEvent; json: TJSONData);
  end;

   { TCEDubProjectEditorWidget }
  TCEDubProjectEditorWidget = class(TCEWidget, ICEProjectObserver)
    btnAcceptProp: TSpeedButton;
    btnAddProp: TSpeedButton;
    btnDelProp: TSpeedButton;
    btnRefresh: TBitBtn;
    edProp: TEdit;
    fltEdit: TTreeFilterEdit;
    imgList: TImageList;
    MenuItem1: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    pnlToolBar: TPanel;
    pnlToolBar1: TPanel;
    propTree: TTreeView;
    fltInspect: TTreeFilterEdit;
    treeInspect: TTreeView;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure btnAcceptPropClick(Sender: TObject);
    procedure btnAddPropClick(Sender: TObject);
    procedure btnDelPropClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure propTreeSelectionChanged(Sender: TObject);
    procedure treeInspectDblClick(Sender: TObject);
  private
    fSelectedNode: TTreeNode;
    fProj: TCEDubProject;
    fNodeSources: TTreeNode;
    fNodeConfig: TTreeNode;
    procedure updateEditor;
    procedure updateInspector;
    procedure updateValueEditor;
    procedure setJsonValueFromEditor;
    procedure addProp(const propName: string; tpe: TJSONtype);
    //
    procedure projNew(project: ICECommonProject);
    procedure projChanged(project: ICECommonProject);
    procedure projClosing(project: ICECommonProject);
    procedure projFocused(project: ICECommonProject);
    procedure projCompiling(project: ICECommonProject);
    procedure projCompiled(project: ICECommonProject; success: boolean);
    //
  protected
    procedure SetVisible(value: boolean); override;
  public
    constructor create(aOwner: TComponent); override;
  end;

implementation
{$R *.lfm}

const
  proposals: array[0..42] of TEditorProposal = (
    (name: 'authors';             jtype: ptArray),
    (name: 'buildOptions';        jtype: ptArray),
    (name: 'buildRequirements';   jtype: ptArray),
    (name: 'buildTypes';          jtype: ptObject),
    (name: 'configurations';      jtype: ptArray),
    (name: 'copyFiles';           jtype: ptArray),
    (name: 'copyright';           jtype: ptValue),
    (name: 'cov';                 jtype: ptArray),
    (name: 'ddoc';                jtype: ptArray),
    (name: 'ddoxFilterArgs';      jtype: ptArray),
    (name: 'debug';               jtype: ptArray),
    (name: 'debugVersions';       jtype: ptArray),
    (name: 'dependencies';        jtype: ptObject),
    (name: 'description';         jtype: ptValue),
    (name: 'dflags';              jtype: ptArray),
    (name: 'docs';                jtype: ptArray),
    (name: 'excludedSourceFiles'; jtype: ptArray),
    (name: 'homepage';            jtype: ptValue),
    (name: 'lflags';              jtype: ptArray),
    (name: 'libs';                jtype: ptArray),
    (name: 'license';             jtype: ptValue),
    (name: 'mainSourceFile';      jtype: ptValue),
    (name: 'name';                jtype: ptValue),
    (name: 'plain';               jtype: ptArray),
    (name: 'platforms';           jtype: ptArray),
    (name: 'postBuildCommands';   jtype: ptArray),
    (name: 'postGenerateCommands';jtype: ptArray),
    (name: 'preBuildCommands';    jtype: ptArray),
    (name: 'preGenerateCommands'; jtype: ptArray),
    (name: 'profile';             jtype: ptArray),
    (name: 'release';             jtype: ptArray),
    (name: 'sourceFiles';         jtype: ptArray),
    (name: 'stringImportPaths';   jtype: ptArray),
    (name: 'subConfigurations';   jtype: ptObject),
    (name: 'subPackages';         jtype: ptArray),
    (name: 'systemDependencies';  jtype: ptValue),
    (name: 'targetName';          jtype: ptValue),
    (name: 'targetPath';          jtype: ptValue),
    (name: 'targetType';          jtype: ptValue),
    (name: 'unittest';            jtype: ptArray),
    (name: 'unittest-cov';        jtype: ptArray),
    (name: 'versions';            jtype: ptArray),
    (name: 'workingDirectory';    jtype: ptValue)
  );

{$REGION TCEDubProjectPropAddPanel ---------------------------------------------}
constructor TCEDubProjectPropAddPanel.construct(event: TDubPropAddEvent; json: TJSONData);
var
  layout: TPanel;
  i: integer;
begin
  inherited create(nil);
  fJson := json;
  width := 280;
  height := 130;
  fEvent := event;
  caption := 'add a DUB property';
  Position := poMainFormCenter;
  ShowHint:=true;
  //
  fSelType := TRadioGroup.Create(self);
  fSelType.Parent := self;
  fSelType.Items.AddStrings(['array', 'object', 'value']);
  fSelType.Align:= alClient;
  fSelType.BorderSpacing.Around:=2;
  fSelType.Caption:= 'type';
  fSelType.ItemIndex:=2;
  fSelType.Hint:= 'type of the property to add';
  fSelType.OnSelectionChanged:= @selTypeChanged;
  //
  layout := TPanel.Create(self);
  layout.Parent := self;
  layout.Align := alBottom;
  layout.Height := 32;
  layout.BevelOuter:= bvNone;
  //
  fEdName := TComboBox.Create(self);
  fEdName.Parent := layout;
  fEdName.Align:=alClient;
  fEdName.BorderSpacing.Around:=4;
  fEdName.Width:=80;
  fEdName.Hint:='name of the property to add';
  for i:= low(proposals) to high(proposals) do
    fEdName.Items.Add(proposals[i].name);
  fEdName.AutoComplete := true;
  fEdName.OnChange := @setSelFromProposal;
  //
  fBtnValidate := TBitBtn.Create(self);
  fBtnValidate.Parent := layout;
  fBtnValidate.Align:=alRight;
  fBtnValidate.BorderSpacing.Around:=4;
  fBtnValidate.Width:= 26;
  fBtnValidate.OnClick:=@doValidate;
  fBtnValidate.Hint:='accept and add a property';
  AssignPng(fBtnValidate, 'ACCEPT');
  //
  selTypeChanged(nil);
end;

procedure TCEDubProjectPropAddPanel.selTypeChanged(sender: TObject);
begin
  if fJson.isNotNil then
    fEdName.Enabled := fJson.JSONType <> TJSONtype.jtArray;
end;

procedure TCEDubProjectPropAddPanel.setSelFromProposal(sender: TObject);
var
  i: integer;
begin
  fSelType.Enabled:=true;
  for i:= low(proposals) to high(proposals) do
  begin
    if fEdName.Text = proposals[i].name then
    begin
      case proposals[i].jtype of
        ptArray:fSelType.ItemIndex:=0;
        ptObject:fSelType.ItemIndex:=1;
        ptValue:fSelType.ItemIndex:=2;
      end;
      fSelType.Enabled := false;
      break;
    end;
  end;
end;

procedure TCEDubProjectPropAddPanel.doValidate(sender: TObject);
var
  tpe: TJSONtype;
begin
  if assigned(fEvent) then
  begin
    case fSelType.ItemIndex of
      0: tpe := TJSONtype.jtArray;
      1: tpe := TJSONtype.jtObject;
      else tpe := TJSONtype.jtString;
    end;
    fEvent(fEdName.Text, tpe);
    Close;
  end;
end;
{$ENDREGION}

{$REGION Standard Comp/Obj -----------------------------------------------------}
constructor TCEDubProjectEditorWidget.create(aOwner: TComponent);
begin
  inherited;
  toolbarVisible:=false;
  fNodeSources := treeInspect.Items[0];
  fNodeConfig := treeInspect.Items[1];
  //
  AssignPng(btnAddProp, 'TEXTFIELD_ADD');
  AssignPng(btnDelProp, 'TEXTFIELD_DELETE');
  AssignPng(btnAcceptProp, 'ACCEPT');
  AssignPng(btnRefresh, 'ARROW_UPDATE');
end;

procedure TCEDubProjectEditorWidget.SetVisible(value: boolean);
begin
  inherited;
  if not value then exit;
  //
  updateEditor;
end;
{$ENDREGION}

{$REGION ICEProjectObserver ----------------------------------------------------}
procedure TCEDubProjectEditorWidget.projNew(project: ICECommonProject);
begin
  fProj := nil;
  enabled := false;
  if project.getFormat <> pfDub then
    exit;
  enabled := true;
  fProj := TCEDubProject(project.getProject);
  //
end;

procedure TCEDubProjectEditorWidget.projChanged(project: ICECommonProject);
begin
  if fProj.isNil then
    exit;
  if project.getProject <> fProj then
    exit;
  if not Visible then
    exit;

  updateEditor;
  updateInspector;
end;

procedure TCEDubProjectEditorWidget.projClosing(project: ICECommonProject);
begin
  if fProj.isNil then
    exit;
  if project.getProject <> fProj then
    exit;
  fProj := nil;
  //
  updateEditor;
  updateInspector;
  enabled := false;
end;

procedure TCEDubProjectEditorWidget.projFocused(project: ICECommonProject);
begin
  fProj := nil;
  enabled := false;
  if project.getFormat <> pfDub then
  begin
    updateEditor;
    updateInspector;
    exit;
  end;
  fProj := TCEDubProject(project.getProject);
  enabled := true;
  if not Visible then
    exit;

  updateEditor;
  updateInspector;
end;

procedure TCEDubProjectEditorWidget.projCompiling(project: ICECommonProject);
begin
end;

procedure TCEDubProjectEditorWidget.projCompiled(project: ICECommonProject; success: boolean);
begin
end;
{$ENDREGION}

{$REGION Editor ----------------------------------------------------------------}
procedure TCEDubProjectEditorWidget.propTreeSelectionChanged(Sender: TObject);
begin
  fSelectedNode := nil;
  btnDelProp.Enabled := false;
  btnAddProp.Enabled := false;
  if propTree.Selected.isNil then exit;
  //
  fSelectedNode := propTree.Selected;
  btnDelProp.Enabled := (fSelectedNode.Level > 0) and (fSelectedNode.Text <> 'name')
    and fSelectedNode.data.isNotNil;
  updateValueEditor;
  btnAddProp.Enabled := TJSONData(fSelectedNode.Data).JSONType in [jtObject, jtArray];
end;

procedure TCEDubProjectEditorWidget.btnAcceptPropClick(Sender: TObject);
begin
  if fSelectedNode.isNil then exit;
  //
  setJsonValueFromEditor;
  propTree.FullExpand;
end;

procedure TCEDubProjectEditorWidget.btnAddPropClick(Sender: TObject);
var
  pnl: TCEDubProjectPropAddPanel;
begin
  if fSelectedNode.isNil then exit;
  //
  pnl := TCEDubProjectPropAddPanel.construct(@addProp, TJSONData(fSelectedNode.Data));
  pnl.ShowModal;
  pnl.Free;
end;

procedure TCEDubProjectEditorWidget.addProp(const propName: string;
  tpe: TJSONtype);
var
  arr: TJSONArray;
  obj: TJSONObject;
  nod: TTreeNode;
begin
  if fSelectedNode.isNil then exit;
  //
  fProj.beginModification;
  if TJSONData(fSelectedNode.Data).JSONType = jtArray then
  begin
    arr := TJSONArray(fSelectedNode.Data);
    case tpe of
      jtArray: arr.Add(TJSONArray.Create());
      jtObject: arr.Add(TJSONObject.Create());
      jtString:arr.Add('<value>');
    end;
  end
  else if TJSONData(fSelectedNode.Data).JSONType = jtObject then
  begin
    obj := TJSONObject(fSelectedNode.Data);
    case tpe of
      jtArray: obj.Add(propName, TJSONArray.Create());
      jtObject: obj.Add(propName, TJSONObject.Create());
      jtString: obj.Add(propName, '<value>');
    end;
  end;
  fProj.endModification;
  propTree.FullExpand;
  nod := propTree.Items.FindNodeWithText('<value>');
  if nod.isNil then
    nod := propTree.Items.FindNodeWithText(propName);
  if nod.isNotNil then
  begin
    propTree.Selected := nod;
    propTree.MakeSelectionVisible;
  end;
end;

procedure TCEDubProjectEditorWidget.btnDelPropClick(Sender: TObject);
var
  prt: TJSONData;
begin
  if fSelectedNode.isNil then exit;
  if fSelectedNode.Level = 0 then exit;
  if fSelectedNode.Text = 'name' then exit;
  if fSelectedNode.Data.isNil then exit;
  if fSelectedNode.Parent.Data.isNil then exit;
  //
  fProj.beginModification;
  prt := TJSONData(fSelectedNode.Parent.Data);
  if prt.JSONType = jtObject then
    TJSONObject(prt).Delete(fSelectedNode.Index)
  else if prt.JSONType = jtArray then
    TJSONArray(prt).Delete(fSelectedNode.Index);
  fProj.endModification;
  //
  updateValueEditor;
end;

procedure TCEDubProjectEditorWidget.btnRefreshClick(Sender: TObject);
begin
  if fProj.isNil or not fProj.filename.fileExists then
      exit;
  fProj.loadFromFile(fProj.filename);
end;

procedure TCEDubProjectEditorWidget.MenuItem1Click(Sender: TObject);
begin
  if fProj.isNil or not fProj.filename.fileExists then
    exit;
  fProj.loadFromFile(fProj.filename);
end;

procedure TCEDubProjectEditorWidget.setJsonValueFromEditor;
var
  dat: TJSONData;
  vFloat: TJSONFloat;
  vInt: integer;
  vInt64: int64;
  vBool: boolean;
begin
  if fSelectedNode.isNil then exit;
  if fSelectedNode.Data.isNil then exit;
  if fProj.isNil then exit;
  //
  fProj.beginModification;
  dat := TJSONData(fSelectedNode.Data);
  case dat.JSONType of
    jtNumber:
      case TJSONNumber(dat).NumberType of
        ntFloat:
          if TryStrToFloat(edProp.Text, vFloat) then
            dat.AsFloat := vFloat;
        ntInt64:
          if TryStrToInt64(edProp.Text, vInt64) then
            dat.AsInt64 := vInt64;
        ntInteger:
          if TryStrToInt(edProp.Text, vInt) then
            dat.AsInteger := vInt;
      end;
     jtBoolean:
      if TryStrToBool(edProp.Text, vBool) then
        dat.AsBoolean := vBool;
      jtString:
        dat.AsString := edProp.Text;
  end;
  fProj.endModification;
end;

procedure TCEDubProjectEditorWidget.updateValueEditor;
var
  dat: TJSONData;
begin
  edProp.Clear;
  if fSelectedNode.isNil then exit;
  if fSelectedNode.Data.isNil then exit;
  //
  dat := TJSONData(fSelectedNode.Data);
  case dat.JSONType of
    jtNumber:
      case TJSONNumber(dat).NumberType of
        ntFloat:
          edProp.Text := FloatToStr(dat.AsFloat);
        ntInt64:
          edProp.Text := IntToStr(dat.AsInt64);
        ntInteger:
          edProp.Text := IntToStr(dat.AsInteger);
      end;
    jtBoolean:
      edProp.Text := BoolToStr(dat.AsBoolean);
    jtString:
      edProp.Text := dat.AsString;
  end;
end;

procedure TCEDubProjectEditorWidget.updateEditor;

  procedure addPropsFrom(node: TTreeNode; data: TJSONData);
  var
    i: integer;
    c: TTreeNode;
  begin
    node.Data:= data;
    if data.JSONType = jtObject then for i := 0 to data.Count-1 do
    begin
      node.ImageIndex:=7;
      node.SelectedIndex:=7;
      node.StateIndex:=7;
      c := node.TreeNodes.AddChildObject(node, TJSONObject(data).Names[i],
        TJSONObject(data).Items[i]);
      case TJSONObject(data).Items[i].JSONType of
        jtObject, jtArray:
          addPropsFrom(c, TJSONObject(data).Items[i]);
        else begin
          c.ImageIndex:=9;
          c.SelectedIndex:=9;
          c.StateIndex:=9;
        end;
      end;
    end else if data.JSONType = jtArray then for i := 0 to data.Count-1 do
    begin
      node.ImageIndex:=8;
      node.SelectedIndex:=8;
      node.StateIndex:=8;
      c := node.TreeNodes.AddChildObject(node, format('item %d',[i]),
        TJSONArray(data).Items[i]);
      case TJSONArray(data).Items[i].JSONType of
        jtObject, jtArray:
          addPropsFrom(c, TJSONArray(data).Items[i]);
        else begin
          c.ImageIndex:=9;
          c.SelectedIndex:=9;
          c.StateIndex:=9;
        end;
      end;
    end;
  end;

begin
  propTree.Items.Clear;
  edProp.Clear;
  if fProj.isNil or fProj.json.isNil then
    exit;
  //
  propTree.BeginUpdate;
  addPropsFrom(propTree.Items.Add(nil, 'project'), fProj.json);
  propTree.EndUpdate;
end;
{$ENDREGION}

{$REGION Inspector -------------------------------------------------------------}
procedure TCEDubProjectEditorWidget.updateInspector;
var
  i: integer;
  j: integer;
  node : TTreeNode;
begin
  if fNodeConfig.isNil or fNodeSources.isNil then
    exit;
  //
  fNodeConfig.DeleteChildren;
  fNodeSources.DeleteChildren;
  //
  if fProj.isNil then
    exit;
  //
  j := fProj.getActiveConfigurationIndex;
  treeInspect.BeginUpdate;
  for i:= 0 to fProj.configurationCount-1 do
  begin
    if i <> j then
    begin
      node := treeInspect.Items.AddChild(fNodeConfig, fProj.configurationName(i));
      node.ImageIndex := 3;
      node.SelectedIndex := 3;
      node.StateIndex := 3;
    end
    else
    begin
      node := treeInspect.Items.AddChild(fNodeConfig, fProj.configurationName(i) +' (active)');
      node.ImageIndex := 10;
      node.SelectedIndex := 10;
      node.StateIndex := 10;
    end;
  end;
  for i := 0 to fProj.sourcesCount-1 do
  begin
    node := treeInspect.Items.AddChild(fNodeSources, fProj.sourceRelative(i));
    node.ImageIndex := 2;
    node.SelectedIndex := 2;
    node.StateIndex := 2;
  end;
  // first update or update cause by editor
  if (not fNodeConfig.Expanded) and (not fNodeSources.Expanded) then
    treeInspect.FullExpand;
  treeInspect.EndUpdate;
end;

procedure TCEDubProjectEditorWidget.treeInspectDblClick(Sender: TObject);
var
  node: TTreeNode;
  fname: string;
begin
  if treeInspect.Selected.isNil then exit;
  if fProj.isNil then exit;
  node := treeInspect.Selected;
  // open file
  if node.Parent = fNodeSources then
  begin
    fname := fProj.sourceAbsolute(node.Index);
    if isEditable(fname.extractFileExt) then
      getMultiDocHandler.openDocument(fname);
  end
  // select active config
  else if node.Parent = fNodeConfig then
  begin
    fProj.setActiveConfigurationIndex(node.Index);
    fNodeConfig.Expand(true);
  end;
end;
{$ENDREGION}

end.

