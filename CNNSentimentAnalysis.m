%% CMPT-741: sentiment analysis base on Convolutional Neural Network
% author: Jay Maity
% date: 15-11-2016

clear; clc;

%% Section 1: preparation before training

% section 1.1 read file 'train.txt', load data and vocabulary by using function read_data()
[data, wordMap] = read_data();
% section 1.2 Initialization with random numbers
d = 5;
total_words = length(wordMap);

% random sample from normal distribution
% with mean = 0 , variance = 0.01
T = normrnd(0, 0.1, [total_words, d]);

% section 1.3 Initialization of filters
filter_size = [2,3,4];
n_filter = 2;

W_conv = cell(length(filter_size), 1);
B_conv = cell(length(filter_size), 1);

for i = 1: length(filter_size)
    % get filter size
    f = filter_size(i);
    % inint W with FW x FH x FC x K
    W_conv{i} = normrnd(0, 0.1, [f, d, 1, n_filter]);
    B_conv{i} = zeros(n_filter, 1);
end

% section 1.4 init output layer
total_filter = length(filter_size) * n_filter;
n_class = 2;
W_out = normrnd(0, 0.1, [total_filter, n_class]);
B_out = zeros(n_class, 1);

filter_fully_connected = normrnd(0, 0.1, [1,3,2,n_class]);

%% Section 2: training
% Note: 
% you may need the resouces [2-4] in the project description.
% you may need the follow MatConvNet functions: 
%       vl_nnconv(), vl_nnpool(), vl_nnrelu(), vl_nnconcat(), and vl_nnloss()

% for each example in train.txt do
% section 2.1 forward propagation and compute the loss
% get sentence matrix
% words_indexes = [wordMap('i'), wordMap('like'),
% ...., wordMap('!')]

total_sentences = 6000;
% Setup MatConvNet.
run matlab/vl_setupnn ;
for sentence_no = 1: total_sentences
    word_indexes = [];
    
    word_cell = data(sentence_no, 2);
    word_texts = word_cell{1};
    for word_index = 1:length(word_texts)
        text = word_texts(word_index);
        word_indexes(word_index) = wordMap(text{1});
    end
    
    X = T(word_indexes, :);
    pool_res = cell(1, length(filter_size));
    cache = cell(2, length(filter_size));
    
    for i = 1: length(filter_size)
        
        % convolution operation
        conv = vl_nnconv(X, W_conv{i}, B_conv{i});
        
        % apply activation function :relu
        relu = vl_nnrelu(conv);

        % 1-max pooling operation
        sizes = size(conv);
        pool = vl_nnpool(relu, [sizes(1), 1]);

        %importatnt: keeping the values for back propagation
        cache{2, i} = relu;
        cache{1, i} = conv;
        pool_res{i} = pool;
    end

    z = vl_nnconcat(pool_res, 2);
    concat = z;
    
    % use of vl_nnconv function to act as fully connected layer
    % https://github.com/vlfeat/matconvnet/issues/185
    output_a = vl_nnconv(z, filter_fully_connected, []);
    output_softmax = vl_nnsoftmax(output_a);
    
    t_arr = data(sentence_no, 3);
    t = t_arr{1};
    
%     my_t = zeros(1,2,1,1);
%     if t == 1
%         my_t(:,1,:,1) = 1;
%         my_t(:,1,:,1) = 0;
%     else
%         my_t(:,1,:,1) = 0;
%         my_t(:,1,:,1) = 0;
%     end
    if t == 0
        t= -1;
    end
       
    loss = vl_nnloss(output_softmax, t);
    disp(loss)
    
    % section 2.2 backward propagation and compute the derivatives
    if 4 > 3
      dzdx3 = vl_nnloss(output_softmax, t, 1);
      [dzdx2, dzdw2] = vl_nnconv(z, filter_fully_connected, [], dzdx3);
      dzdx1 = vl_nnconcat(pool_res, 2, dzdx2);
      for i = 1; length(filter_size)
          
        % 1-max pooling operation
        sizes = size(pool_res{i});
        dzdx0 = vl_nnpool(pool_res{i}, [sizes(1), 1], dzdx1{i});
        
        % apply activation function :relu
        dzdx = vl_nnrelu(cache{2, i}, dzdx0);
        
        % convolution operation
        [a, b] = vl_nnconv(cache{1, i},W_conv{i}, [], dzdx);
        
      end
    end
end
    

    % section 2.3 update the parameters
    % TODO: your code