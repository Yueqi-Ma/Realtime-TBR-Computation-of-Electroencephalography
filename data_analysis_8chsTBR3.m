%%
clear;clc;close all;

%% 全局变量
n = 15; % 一次读入的点数，1个点33个字节

global x;
global powerSpectrum;

for i = 1:9
    eval(['global',' ch',num2str(i),';'])
    eval(['global',' sp',num2str(i),';'])
    eval(['ch',num2str(i) '= 0;']);
end

global step;

step = n; % 坐标轴补偿，应该和读入字节数相同

t = 0;
m = 0;
x = 0;
powerSpectrum = [];

%% TCPIP连接设置
interfaceObject = tcpip('127.0.0.1', 12349, 'NetworkRole', 'client');
interfaceObject.InputBuffersize = 33 * n;
interfaceObject.RemoteHost = '127.0.0.1';
bytesToRead = 33 * n;

% 设置窗口
figureHandle = figure('NumberTitle', 'off',...
    'Name', 'TBR动态图',...
    'Color', [1 1 1],...
    'position', [1 1 1536 864/3],...
    'CloseRequestFcn', {@localCloseFigure, interfaceObject});

% 设置axis
axesHandle = axes('Parent', figureHandle,...
    'YGrid', 'on',...
    'YColor', [1 1 1],...
    'XGrid', 'on',...
    'XColor', [0 0 0],...
    'Color', [0 0 0]);
xlabel(axesHandle, '时间');
ylabel(axesHandle, 'TBR');

%% 初始化绘图
plotHandle = plot(0, '-', 'LineWidth', 1, 'color', [0 0 1]);
grid minor

% 定义当输入缓冲区中达到所需字节数时要执行的回调函数
interfaceObject.BytesAvailableFcn = {@read, plotHandle, bytesToRead};
interfaceObject.BytesAvailableFcnMode = 'byte';
interfaceObject.BytesAvailableFcnCount = bytesToRead;
fopen(interfaceObject);

pause(2);
fprintf(interfaceObject, 'b');

%% 初始化PSD计算相关变量
bufferSize = 500;% 缓存大小，用于计算功率谱密度
bufferCount = 0;%缓存计数器
thetaFreqRange = [4 8]; % θ波频率范围
betaFreqRange = [12 30]; % β波频率范围
thetaPSD = []; % 存储θ波频率段的PSD
betaPSD = []; % 存储β波频率段的PSD
tbr = []; % 存储TBR值

while isvalid(interfaceObject)
    % 检查是否有足够的数据读取
    if interfaceObject.BytesAvailable >= bytesToRead
        data_recv = fread(interfaceObject, bytesToRead);
        data_recv1 = reshape(data_recv, [33, n])';
        
        % 将接收到的数据转换为信号向量
        data = double(data_recv1(:, 2:33));
        
        % 更新全局变量x
        x = [x; data(:)];
        
        % 更新缓存计数器
        bufferCount = bufferCount + size(data, 1);
        
        % 如果缓存已满，则计算功率谱密度并绘制
        if bufferCount >= bufferSize
            % 计算当前缓存中数据的功率谱密度（PSD）
            [pxx, f] = pwelch(x(end-bufferCount+1:end), [], [], [], 1000);
            
            % 计算θ波频率段的平均PSD
            thetaIdx = find(f >= thetaFreqRange(1) & f <= thetaFreqRange(2));
            thetaAvgPSD = mean(pxx(thetaIdx));
            thetaPSD = [thetaPSD; thetaAvgPSD];
            
            % 计算β波频率段的平均PSD
            betaIdx = find(f >= betaFreqRange(1) & f <= betaFreqRange(2));
            betaAvgPSD = mean(pxx(betaIdx));
            betaPSD = [betaPSD; betaAvgPSD];
            
            % 计算TBR值
            tbrValue = thetaAvgPSD / betaAvgPSD;
            tbr = [tbr; tbrValue];
            
            % 清空缓存计数器
            bufferCount = 0;
            
            % 绘制动态图
            t = t + 1;
            plot(axesHandle, 1:t, tbr, '-', 'LineWidth', 1, 'color', [0 0 1]);
             %xlim(axesHandle, [1 t]);
             xlabel(axesHandle, '时间');
            %ylim(axesHandle, [min(tbr) max(tbr)]);
            ylabel(axesHandle, 'TBR');
            
            drawnow;
        end
    end
end

%% 关闭TCP/IP连接
fclose(interfaceObject);
delete(interfaceObject);
clear interfaceObject;

%% 关闭窗口的回调函数
function localCloseFigure(~, ~, interfaceObject)
    fclose(interfaceObject);
    delete(interfaceObject);
    clear interfaceObject;
    delete(gcf);
    %closereq;
end

%% 读取数据的回调函数
function read(interfaceObject, ~, plotHandle, bytesToRead)
    global x;
    global powerSpectrum;
    
    % 读取数据
    if interfaceObject.BytesAvailable >= bytesToRead
        data_recv = fread(interfaceObject, bytesToRead);
        data_recv1 = reshape(data_recv, [33, n])';
        
        % 将接收到的数据转换为信号向量
        data = double(data_recv1(:, 2:33));
        
        % 更新全局变量x
        x = [x; data(:)];
        
        % 更新缓存计数器
        bufferCount = bufferCount + size(data, 1);
        
        % 如果缓存已满，则计算功率谱密度并绘制
        if bufferCount >= bufferSize
            % 计算当前缓存中数据的功率谱密度（PSD）
            [pxx, f] = pwelch(x(end-bufferCount+1:end), [], [], [], 1000);
            
            % 计算θ波频率段的平均PSD
            thetaIdx = find(f >= thetaFreqRange(1) & f <= thetaFreqRange(2));
            thetaAvgPSD = mean(pxx(thetaIdx));
            thetaPSD = [thetaPSD; thetaAvgPSD];
            
            % 计算β波频率段的平均PSD
            betaIdx = find(f >= betaFreqRange(1) & f <= betaFreqRange(2));
            betaAvgPSD = mean(pxx(betaIdx));
            betaPSD = [betaPSD; betaAvgPSD];
            
            % 计算TBR值
            tbrValue = thetaAvgPSD / betaAvgPSD;
            tbr = [tbr; tbrValue];
            
            % 清空缓存计数器
            bufferCount = 0;
            
            % 绘制动态图
            t = t + 1;
            plot(axesHandle, 1:t, tbr, '-', 'LineWidth', 1, 'color', [0 0 1]);
            %xlim(axesHandle, [1 t]);
             xlabel(axesHandle, '时间');
            %ylim(axesHandle, [min(tbr) max(tbr)]);
            ylabel(axesHandle, 'TBR');
            
            drawnow;
        end
    end
end