warning off
clear;
clc;
close all;
%%
%计算了所有通道合并数据的PSD
%%
% 全局变量
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

% TCPIP连接设置
interfaceObject = tcpip('127.0.0.1', 12349, 'NetworkRole', 'client'); % 与第一个请求连接的客户机建立连接，端口号为10008，类型为服务器。
interfaceObject.InputBuffersize = 33 * n; % 缓存%缓存%缓存%缓存%缓存%缓存%缓存%缓存%缓存%缓存%缓存%缓存%%%%%%%%%%%
interfaceObject.RemoteHost = '127.0.0.1'; % 客户端ip
% 设置一次读取的字节数
bytesToRead = 33 * n;

% 设置窗口
figureHandle = figure('NumberTitle', 'off',...
    'Name', 'PSD动态图',...% 窗口名
    'Color', [1 1 1],...% 颜色
    'position', [1 1 1536 864/3],...% 设置全屏显示 get(0,'ScreenSize')
    'CloseRequestFcn', {@localCloseFigure, interfaceObject});

% 设置axis
axesHandle = axes('Parent', figureHandle,...
    'YGrid', 'on',...    % 显示Y轴
    'YColor', [1 1 1],...% Y轴设置白色
    'XGrid', 'on',...
    'XColor', [0 0 0],...% 显示X轴
    'Color', [0 0 0]);  % X轴设置白色
xlabel(axesHandle, '时间');% X轴标签
ylabel(axesHandle, 'PSD');   % Y轴标签

% 初始化绘图
plotHandle = plot(0, '-', 'LineWidth', 1, 'color', [0 0 1]);
grid minor

% 定义当输入缓冲区中达到所需字节数时要执行的回调函数  注意：回调函数必须在开启服务之前
interfaceObject.BytesAvailableFcn = {@read, plotHandle, bytesToRead}; % 可读字节数回调函数，当可读取字节数超过一定范围或者接收特定的结束符时候才调用
interfaceObject.BytesAvailableFcnMode = 'byte'; % 设置BytesAvailableFcn的函数调用模式
interfaceObject.BytesAvailableFcnCount = bytesToRead; % 调用BytesAvailableFcn的字节数
fopen(interfaceObject); % 打开服务器，直到建立一个TCP连接才返回；

pause(2);
fprintf(interfaceObject, 'b'); % 开启服务

% 初始化功率谱密度计算相关变量
bufferSize = 500; % 缓存大小，用于计算功率谱密度
bufferCount = 0; % 缓存计数器

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
            % 计算功率谱密度（PSD）
            [pxx, f] = pwelch(x(end-bufferCount+1:end), [], [], [], 1000);
            
            % 更新功率谱变量
            powerSpectrum = [powerSpectrum; pxx];
            
            % 清空缓存计数器
            bufferCount = 0;
            
            % 绘制动态图
            plot(axesHandle, t+(1:length(powerSpectrum)), powerSpectrum, 'LineWidth', 1, 'color', [0 0 1]);
            xlabel(axesHandle, '时间');
            ylabel(axesHandle, 'PSD');
            title(axesHandle, 'PSD动态图');
            drawnow;
        end
    end
end

% 关闭连接
fclose(interfaceObject);
delete(interfaceObject);



%%
function localCloseFigure(~, ~, interfaceObject)
    % 关闭连接
    fclose(interfaceObject);
    delete(interfaceObject);
    % 关闭窗口
    closereq;
end



%%
function read(interfaceObject, ~, plotHandle, bytesToRead)
    global step;
    global x;
    global powerSpectrum;
    
    % 读取数据
    data_recv = fread(interfaceObject, bytesToRead);
    data_recv1 = reshape(data_recv, [33, bytesToRead/33])';
    
    % 将接收到的数据转换为信号向量
    data = double(data_recv1(:, 2:33));
    
    % 更新全局变量x
    x = [x; data(:)];
    
    % 计算功率谱密度
    [pxx, ~] = pwelch(x(end-bytesToRead+1:end), [], [], [], 1000);
    
    % 更新功率谱变量
    powerSpectrum = [powerSpectrum; pxx];
    
    % 绘制动态图
    t = (1:length(powerSpectrum)) + step;
    plot(plotHandle, t, powerSpectrum, 'LineWidth', 1, 'color', [0 0 1]);
    xlabel('时间');
    ylabel('PSD');
    title('PSD动态图');
    drawnow;
end