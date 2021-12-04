// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity >=0.4.22 <0.9.0;
// count, like, donate
contract SmartBlogs {

	enum BlogType {PAID, UNPAID}

	struct Blog {
		uint blogId;
		string blogTitle;
		string blogContent;
		BlogType paid;
		uint value;
		address payable ownerId;
		uint purchasedBy;
		uint likes;
	}

	struct BlogTitle {
		uint blogId;
		string blogTitle;
		BlogType paid;
		uint value;
		address ownerId;
		uint purchasedBy;
		uint likes;
	}


	uint blogCounter = 0;
	// @dev address of the person who is the owner of a blog
	mapping(uint => address) owners;
	// @dev addresses of the viewers who have viewed a particular blog
	mapping(uint => address[]) viewers;
	// @dev list of blogs which each person has viewed - paid or unpaid
	mapping(address => Blog[]) myPaidBlogs;
	// @dev list of blogs which each person has added
	mapping(address => Blog[]) myOwnedBlogs;
	// @dev addresses of all people who have liked a particular blog
	mapping(uint => address[]) likes;

	// @dev list of all the blogs posted
	Blog[] private blogs;

	modifier onlyOwner(uint blogId) {
		require(
			owners[blogId] == msg.sender,
			"You are not the owner of this blog"
		);
		_;
	}

	modifier validBlogId(uint blogId) {
		require(
			blogId >= 0 && blogId < blogs.length,
			"Invalid blog ID"
		);
		_;
	}

	/**
     * @notice adds a new blog
     * @param blogTitle title of the new blog
     * @param blogContent content of the blog 
     * @param value asking price of the blog
     */
	function addBlog(string memory blogTitle, string memory blogContent, uint value) public {
		Blog memory blog = Blog(blogCounter, blogTitle, blogContent, value == 0 ? BlogType.UNPAID : BlogType.PAID, value, msg.sender, 0, 0);
		owners[blogCounter] = msg.sender;
		myOwnedBlogs[msg.sender].push(blog);
		blogs.push(blog);
		blogCounter++;
	}

	/**
     * @notice lists all the blogs
     */
	function listBlogs() public view returns (BlogTitle[] memory) {
		BlogTitle[] memory blogsWithOnlyTitles = new BlogTitle[](blogs.length);
		for(uint i = 0; i < blogs.length; i++) {
			BlogTitle memory blogWithOnlyTitle = BlogTitle(blogs[i].blogId, blogs[i].blogTitle, blogs[i].paid, blogs[i].value, blogs[i].ownerId, blogs[i].purchasedBy, blogs[i].likes);
			blogsWithOnlyTitles[i] = blogWithOnlyTitle;
		}
		return blogsWithOnlyTitles;
	}

	/**
     * @notice lists all the free blogs
     */
	function listFreeBlogs() public view returns (BlogTitle[] memory) {
		uint numFreeBlogs = 0;
		for(uint i = 0; i < blogs.length; i++) {
			if(blogs[i].value != 0) {
				numFreeBlogs++;
			}
		}
		BlogTitle[] memory blogsWithOnlyTitles = new BlogTitle[](numFreeBlogs);
		uint index = 0;
		for(uint i = 0; i < blogs.length; i++) {
			if(blogs[i].value == 0) {
				blogsWithOnlyTitles[index++] = BlogTitle(blogs[i].blogId, blogs[i].blogTitle, blogs[i].paid, blogs[i].value, blogs[i].ownerId, blogs[i].purchasedBy, blogs[i].likes);
			}
		}
		return blogsWithOnlyTitles;
	}

	/**
     * @notice pays the blog creator the asking price
     * @param blogId id of the blog for which the price is being paid
     */
	function payForBlog(uint blogId) public payable {
		bool flag = false;
		for(uint i = 0; i < myPaidBlogs[msg.sender].length; i++) {
			if(blogId == myPaidBlogs[msg.sender][i].blogId) {
				flag = true;
				break;
			}
		}
		require(
			flag == false,
			"You have already paid for this blog !"
		);

		require(
			msg.value == blogs[blogId].value,
			"Sent amount should be equal to blog price !"
		);
		
		viewers[blogId].push(msg.sender);
		blogs[blogId].purchasedBy = viewers[blogId].length;
		myPaidBlogs[msg.sender].push(blogs[blogId]);

		address payable ownerAddress = blogs[blogId].ownerId;
		ownerAddress.transfer(blogs[blogId].value);
	}


	/**
     * @notice view a particular blog
     * @param blogId id of the blog
     */
	function viewBlog(uint blogId) public view returns (Blog memory) {
		if(blogs[blogId].value == 0) {
			return blogs[blogId];
		}

		bool flag = false;
		for(uint i = 0; i < myPaidBlogs[msg.sender].length; i++) {
			if(blogId == myPaidBlogs[msg.sender][i].blogId) {
				flag = true;
				break;
			}
		}
		require(
			flag, "You have not paid for this blog !!!"
		);

		return blogs[blogId];
	}

	/**
     * @notice get all the blogs you have bought
     */
	function getBlogsPaidFor() public view returns (Blog[] memory) {
		return myPaidBlogs[msg.sender];
	}

	/**
     * @notice get blogs created by you
     */
	function getOwnedBlogs() public view returns (Blog[] memory) {
		return myOwnedBlogs[msg.sender];
	}

	/**
     * @notice get the addreseses of people who have purchased a particular blog
     * @param blogId id of the blog
     */
	function getBlogViewers(uint blogId) public view onlyOwner(blogId) returns(address[] memory) {
		return viewers[blogId];
	}

	/**
     * @notice donates money to the creator of particular blog
     * @param blogId id of the blog
     */
	function donate(uint blogId) public payable {
		address payable ownerAddress = blogs[blogId].ownerId;
		ownerAddress.transfer(msg.value);
	}

	/**
     * @notice like a particular blog
     * @param blogId id of the blog
     */
	function likeBlog(uint blogId) public validBlogId(blogId) {
		bool alreadyLiked = false;
		for(uint i = 0; i < likes[blogId].length; i++) {
			if(likes[blogId][i] == msg.sender) {
				alreadyLiked = true;
			}
		}
		if(alreadyLiked) return;
		likes[blogId].push(msg.sender);
		blogs[blogId].likes += 1;
	}
	constructor() public {
		
	}
}
