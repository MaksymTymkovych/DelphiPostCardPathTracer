program dPostCardPathTracer;

{$APPTYPE CONSOLE}

uses
  Math;

type
  Float = Single;

  PVec = ^TVec;
  TVec = record
    x,y,z: Float;
    class procedure Writeln(const v: TVec); static;
    class function Vec(const v: Float = 0): TVec; overload; static;
    class function Vec(const x: Float; const y: Float; const z: Float = 0): TVec; overload; static;
    class operator Implicit(const v: Float): TVec;
    class operator Add(const a,b: TVec): TVec;
    class operator Multiply(const a,b: TVec): TVec;
    class operator Modulus(const a,b: TVec): Float;
    class operator LogicalNot(const a: TVec): TVec;
  end;

class function TVec.Vec(const v: Float): TVec;
begin
  Result.x := v; Result.y := v; Result.z := v;
end;

class function TVec.Vec(const x, y, z: Float): TVec;
begin
  Result.x := x; Result.y := y; Result.z := z;
end;

class procedure TVec.Writeln(const v: TVec);
begin
  System.Writeln(v.x,' ',v.y,' ',v.z);
end;

class operator TVec.Add(const a,b: TVec): TVec;
begin
  Result.x := a.x + b.x; Result.y := a.y + b.y; Result.z := a.z + b.z;
end;

class operator TVec.Multiply(const a,b: TVec): TVec;
begin
  Result.x := a.x * b.x; Result.y := a.y * b.y; Result.z := a.z * b.z;
end;

class operator TVec.Modulus(const a,b: TVec): Float;
begin
  Result := a.x * b.x + a.y * b.y + a.z * b.z;
end;

class operator TVec.Implicit(const v: Float): TVec;
begin
  Result := Vec(v);
end;

class operator TVec.LogicalNot(const a: TVec): TVec;
begin
  Result := a * (1/(sqrt(a mod a)));
end;

function min(const r,l: Float): Float;
begin
  if l<r then Result := l
  else Result := r;
end;

function randomVal(): Float;
begin
  Result := Random();
end;

function testBox(position: TVec; lowerLeft: TVec; upperRight: TVec): Float;
begin
  lowerLeft := position + lowerLeft * -1;
  upperRight := upperRight + position * -1;
  Result := -min(min(min(lowerLeft.x,upperRight.x),min(lowerLeft.y,upperRight.y)),min(lowerLeft.z, upperRight.z));
end;

function testSphere(const point, center: TVec; const radius: Float): Float;
var
  delta: TVec;
  distance: Float;
begin
  delta := center + point * -1;
  distance := Sqrt(delta mod delta);
  Result := radius - distance;
end;

function testRectangle(const point: TVec; c1, c2: TVec): Float;
begin
  c1 := point  + c1 * -1;
  c2 := c2 * point * -1;
  Result := min(min(min(c1.x, c2.x),min(c1.y, c2.y)),min(c1.z, c2.z));
end;

function testCarvedBox(const point: TVec; c1, c2: TVec): Float;
begin
  c1 := point + c1 * -1;
  c2 := c2 + point * -1;
  Result := -min(min(min(c1.x,c2.x),min(c1.y,c2.y)),min(c1.z,c2.z));
end;

function testRoom(const point: TVec): Float;
var
  c1, c2, c3, c4: TVec;
begin
  c1 := TVec.Vec(2, 4); c1 := TVec.Vec(5, 2);
  c1 := TVec.Vec(3, 5); c1 := TVec.Vec(4, 4);
  Result := min(testCarvedBox(point, c1, c2),
                testCarvedBox(point, c3, c4));
end;

const
  HIT_NONE = 0;
  HIT_LETTER = 1;
  HIT_WALL = 2;
  HIT_SUN = 3;

function QueryDatabase(const position: TVec; var hitType: Integer): Float;
const
  letters: Array [0 .. 15*4] of Char = '5O5_' + '5W9W' + '5_9_' +
                                           'AEOE' + 'COC_' + 'A_E_' +
                                           'IOQ_' + 'I_QO' +
                                           'UOY_' + 'Y_]O' + 'WW[W' +
                                           'aOa_' + 'aWeW' + 'a_e_' + 'cWiO';
var
  distance: Float;
  sun, roomDist, tf: Float;
  f: TVec;
  i: Integer;
  b,e,o: TVec;
  curves: Array[0..1] of TVec;
begin
  distance := 1e9;
  f := position; f.z := 0;

  i := 0;
  while i < sizeOf(letters) do
  begin
    b := TVec.Vec(Byte(letters[i])-79, Byte(letters[i + 1]) - 79) * 0.5;
    e := TVec.Vec(Byte(letters[i + 2])-79, Byte(letters[i + 3]) - 79) * 0.5 + b * -1;
    o := f + (b + e * min(-min((b + f * -1) mod e / (e mod e), 0
                               ),1)) * -1;

    distance := min(distance, o mod o);
    Inc(i,4);
  end;

  distance := Sqrt(distance);
  curves[0] := TVec.Vec(-11, 6); curves[1] := TVec.Vec(11,6);
  for i := 2-1 downto 0 do
  begin
    o := f + curves[i] * -1;
    if o.x > 0 then
    begin
      tf := Abs(Sqrt(o mod o) - 2);
    end
    else
    begin
      if o.y > 0 then
      begin
        o.y := o.y - 2;
      end
      else
      begin
        o.y := o.y + 2;
      end;
      tf := Sqrt(o mod o);
    end;
    distance := min(distance, tf);
  end;

  distance := Power( Power(distance, 8) + Power(position.z, 8), 0.125) - 0.5;
  hitType := HIT_LETTER;

  roomDist := min( -min(testBox(position, TVec.Vec(-30, -0.5, -30), TVec.Vec(30, 18, 30)),
                        testBox(position, TVec.Vec(-25,  17,  -25), TVec.Vec(25, 20, 25))
                   ),
                   testBox(TVec.Vec(FMod(Abs(position.x),8),
                                    position.y,
                                    position.z),
                           TVec.Vec(1.5, 18.5, -25),
                           TVec.Vec(6.5, 20,    25))
  );

  if roomDist < distance then
  begin
    distance := roomDist;
    hitType := HIT_WALL;
  end;
  sun := 19.9 - position.y;
  if sun < distance then
  begin
    distance := sun;
    hitType := HIT_SUN;
  end;
  Result := distance;
end;

function RayMarching(const origin, direction: TVec; var hitPos, hitNorm: TVec): Integer;
var
  hitType: Integer;
  noHitCount: Integer;
  d: Float;
  total_d: Float;
begin
  hitType := HIT_NONE;
  noHitCount := 0;
  total_d := 0.0;
  while total_d < 100 do
  begin

    hitPos := origin + direction * total_d;
    d := QueryDatabase(hitPos, hitType);
    Inc(noHitCount);
    if (d < 0.01) or (noHitCount > 99) then
    begin
      hitNorm := not TVec.Vec(QueryDatabase(hitPos + TVec.Vec(0.01, 0, 0), noHitCount) - d,
                              QueryDatabase(hitPos + TVec.Vec(0, 0.01, 0), noHitCount) - d,
                              QueryDatabase(hitPos + TVec.Vec(0, 0, 0.01), noHitCount) - d);
      Exit(hitType);
    end;
    total_d := total_d + d;
  end;

  Result := 0;
end;

function Trace(origin, direction: TVec): TVec;
var
  sampledPosition, normal, color, attenuation: TVec;
  lightDirection: TVec;

  bounceCount: Integer;
  hitType: Integer;
  incidence, p, c, s, g, u, v: Float;
begin
  color := 0.0;
  attenuation := 1.0;
  lightDirection := not(TVec.Vec(0.6,0.6,1));

  for bounceCount := 3-1 downto 0 do
  begin
    hitType := RayMarching(origin, direction, sampledPosition, normal);
    if hitType = HIT_NONE then Break;
    if hitType = HIT_LETTER then
    begin
      direction := direction + normal * (normal mod direction * -2);
      origin := sampledPosition + direction * 0.1;
      attenuation := attenuation * 0.2;
    end;
    if hitType = HIT_WALL then
    begin
      incidence := normal mod lightDirection;
      p := 6.283185 * randomVal();
      c := randomVal();
      s := Sqrt(1 - c);
      if normal.z < 0 then g := -1 else g := 1;
      u := -1/ (g + normal.z);
      v := normal.x * normal.y * u;
      direction := TVec.Vec(v,
                            g + normal.y * normal.y * u,
                            - normal.y) * (cos(p) * s)
                 + TVec.Vec(1 + g * normal.x * normal.x * u,
                            g * v,
                            -g * normal.x) * (sin(p) * s) + normal * sqrt(c);

      origin := sampledPosition + direction * 0.1;
      attenuation := attenuation * 0.2;
      if (incidence > 0) and
         (RayMarching(sampledPosition + normal * 0.1,
                      lightDirection,
                      sampledPosition,
                      normal)=HIT_SUN) then
      begin
        color := color + attenuation * TVec.Vec(500,400,100) * incidence;
      end;

    end;
    if hitType = HIT_SUN then
    begin
      color := color + attenuation * TVec.Vec(50,80,100); Break;
    end;
  end;

  Result := color;
end;

const
  w = 300;//960;
  h = 300;//540;
  samplesCount = 5;//8;

var
  position,
  goal,left,up: TVec;
  y,x,p: Integer;
  color,o: TVec;

  OutF: TextFile;
begin
  AssignFile(OutF,'pixar.ppm');
  Rewrite(OutF);
  position :=  TVec.Vec(-22, 5, 25);
  goal := not(TVec.Vec(-3, 4, 0) + position * -1);
  left := (not TVec.Vec(goal.z, 0, -goal.x)) * (1. / w);

  up := TVec.Vec(goal.y * left.z - goal.z * left.y,
         goal.z * left.x - goal.x * left.z,
         goal.x * left.y - goal.y * left.x);

  Write(OutF,'P6 ',w,' ',h,' 255 ');
  for y := h-1 downto 0 do
    for x := w-1 downto 0 do
    begin
      color := TVec.Vec();
      for p:= samplesCount-1 downto 0 do
        color := color + Trace(position, not(goal + left * (x - w / 2 + randomVal())+
        up * (y - h / 2 + randomVal())));

      color := color * (1. / samplesCount) + 14. / 241;
      o := color + 1;
      color := TVec.Vec(color.x / o.x, color.y / o.y, color.z / o.z) * 255;
      Write(OutF,AnsiChar(Trunc(color.x)),AnsiChar(Trunc(color.y)),AnsiChar(Trunc(color.z)));
    end;
  CloseFile(OutF);
end.
